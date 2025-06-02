locals {
  datastream_map = {
    for config in var.datastream_configs : config.stream_id => config
  }

  // datasets_to_create_map: Identifies datasets to be created and managed by this Terraform configuration,
  // primarily when bq_dataset_id_prefix is used by a stream configuration.
  datasets_to_create_map = merge(flatten([
    for stream_config_key, stream_config_value in local.datastream_map : [
      if stream_config_value.bq_target_dataset_id == null && stream_config_value.bq_dataset_id_prefix != null : {
        for pg_schema in stream_config_value.postgres_include_schemas :
        # Unique key for the dataset resource, combining stream and source schema name
        format("%s-%s", stream_config_key, pg_schema.schema) => {
          project_id        = var.project_id
          dataset_id_short  = format("%s%s", stream_config_value.bq_dataset_id_prefix, pg_schema.schema)
          location          = stream_config_value.bq_dataset_location
          stream_config_key_ref = stream_config_key // Reference back to the stream config
        }
      } else {} // Empty map if bq_target_dataset_id is set, as these datasets are not "prefix-managed"
    ]
  ])...)

  // tables_to_create_flat_map: Creates a flattened map of all BigQuery tables that need to be created.
  // The key is a unique identifier for each table resource.
  tables_to_create_flat_map = merge(flatten([
    for stream_config_key, stream_config_value in local.datastream_map : [
      for pg_schema in stream_config_value.postgres_include_schemas : [
        for pg_table in pg_schema.tables : {
          format("%s-%s-%s", stream_config_key, pg_schema.schema, (pg_table.target_table_name != null ? pg_table.target_table_name : pg_table.table_name)) => {
            table_resource_project_id      = var.project_id
            table_resource_dataset_id_short = stream_config_value.bq_target_dataset_id != null ?
                                              stream_config_value.bq_target_dataset_id :
                                              format("%s%s", stream_config_value.bq_dataset_id_prefix, pg_schema.schema)
            table_resource_table_id        = (pg_table.target_table_name != null ? pg_table.target_table_name : pg_table.table_name)
            table_resource_schema_fields   = pg_table.schema_fields
            table_resource_time_partitioning = pg_table.time_partitioning
            table_resource_clustering_fields = pg_table.clustering_fields
            stream_id_ref                  = stream_config_key // Used for depends_on in the stream resource
          }
        }
      ]
    ]
  ])...)

  target_dataset_ids_map = {
    for stream_cfg in var.datastream_configs :
    stream_cfg.bq_target_dataset_id => {
      project_id = var.project_id
      dataset_id = stream_cfg.bq_target_dataset_id
    } if stream_cfg.bq_target_dataset_id != null
  }
}

# Create BigQuery Datasets if using prefix-based naming (source hierarchy mode)
resource "google_bigquery_dataset" "managed_pg_schema_datasets" {
  for_each = local.datasets_to_create_map

  project_id                  = each.value.project_id
  dataset_id                  = each.value.dataset_id_short
  location                    = each.value.location
  delete_contents_on_destroy  = true # REVIEW: Set to false for production

  labels = {
    "created_by"  = "terraform-datastream-module"
    "stream_id"   = each.value.stream_config_key_ref
    "source_schema" = split("-", each.key)[1] # Extracts source schema from the map key (e.g. stream1-public -> public)
  }
}

# Data source to validate existence of externally managed target datasets
data "google_bigquery_dataset" "referenced_target_datasets" {
  for_each = local.target_dataset_ids_map

  project_id = each.value.project_id
  dataset_id = each.value.dataset_id

  # This data source will fail if the dataset does not exist,
  # ensuring that streams targeting an explicit bq_target_dataset_id
  # are pointing to a valid, existing dataset.
}

resource "google_bigquery_table" "all_tables" {
  for_each = local.tables_to_create_flat_map

  project    = each.value.table_resource_project_id
  dataset_id = each.value.table_resource_dataset_id_short # This correctly uses the short dataset ID
  table_id   = each.value.table_resource_table_id

  # Schema must be a JSON string
  schema = jsonencode(each.value.table_resource_schema_fields)

  dynamic "time_partitioning" {
    for_each = each.value.table_resource_time_partitioning != null ? [each.value.table_resource_time_partitioning] : []
    content {
      type                       = time_partitioning.value.type
      field                      = time_partitioning.value.field
      expiration_ms              = lookup(time_partitioning.value, "expiration_ms", null)
      require_partition_filter   = lookup(time_partitioning.value, "require_partition_filter", false)
    }
  }

  clustering = each.value.table_resource_clustering_fields # This should be a list of strings

  deletion_protection = false # REVIEW: Set to true for production tables if needed

  labels = {
    "created_by"  = "terraform-datastream-module"
    "stream_id"   = each.value.stream_id_ref
    "source_table_name" = split("-", each.key)[2] # Extracts original source table name from map key (e.g. stream1-public-orders -> orders)
  }

  # Ensure tables depend on their respective datasets if those datasets are managed by this config.
  # This is implicitly handled if dataset_id refers to a dataset created here,
  # but explicit depends_on can be added if complex inter-dependencies arise with dataset creation logic.
  # For datasets referenced via `data.google_bigquery_dataset.referenced_target_datasets`,
  # their existence is checked by the data source. If a dataset from `local.datasets_to_create_map`
  # matches `each.value.table_resource_dataset_id_short`, Terraform creates the dependency.
}

resource "google_datastream_stream" "streams" {
  for_each = local.datastream_map

  provider     = google-beta
  project      = var.project_id
  location     = each.value.location
  stream_id    = each.value.stream_id
  display_name = each.value.display_name

  source_config {
    source_connection_profile = each.value.source_connection_profile
    postgresql_source_config {
      include_objects {
        dynamic "postgresql_schemas" {
          for_each = each.value.postgres_include_schemas # This is list(object({schema=string, tables=list(object({table_name=string, ...}))}))
          iterator = pg_schema_config
          content {
            schema = pg_schema_config.value.schema
            dynamic "postgresql_tables" {
              for_each = pg_schema_config.value.tables
              iterator = pg_table_config
              content {
                table   = pg_table_config.value.table_name
                columns = pg_table_config.value.columns
              }
            }
          }
        }
      }
      dynamic "exclude_objects" { # Assuming var.datastream_configs.postgres_exclude_objects is list(object({schema=string, tables=list(string)}))
        for_each = each.value.postgres_exclude_objects != null ? each.value.postgres_exclude_objects : []
        iterator = exclude_config_item
        content {
          postgresql_schemas {
            schema = exclude_config_item.value.schema
            dynamic "postgresql_tables" {
              for_each = exclude_config_item.value.tables # Assumes tables is a list of strings
              iterator = excluded_table_name_iterator
              content {
                table = excluded_table_name_iterator.value
              }
            }
          }
        }
      }
      publication      = each.value.publication_name
      replication_slot = each.value.replication_slot_name
    }
  }

  destination_config {
    destination_connection_profile = each.value.destination_connection_profile
    bigquery_destination_config {
      dynamic "single_target_dataset" {
        for_each = each.value.bq_target_dataset_id != null ? [each.value.bq_target_dataset_id] : []
        iterator = bq_target_ds_id_iterator # Use an iterator here
        content {
          dataset_id = data.google_bigquery_dataset.referenced_target_datasets[bq_target_ds_id_iterator.value].id
        }
      }
      dynamic "source_hierarchy_datasets" {
        for_each = each.value.bq_target_dataset_id == null ? [1] : []
        content {
          dataset_template {
            location          = each.value.bq_dataset_location
            dataset_id_prefix = each.value.bq_dataset_id_prefix
          }
        }
      }
      data_freshness = each.value.bq_data_freshness
    }
  }

  dynamic "backfill_all" {
    for_each = each.value.backfill_strategy == "all" ? [1] : []
    content {}
  }

  dynamic "backfill_none" {
    for_each = each.value.backfill_strategy == "none" ? [1] : []
    content {}
  }

  desired_state = each.value.run_immediately ? "RUNNING" : "NOT_STARTED"

  depends_on = [
    for k, v in local.tables_to_create_flat_map :
    google_bigquery_table.all_tables[k] if v.stream_id_ref == each.key
  ]
}