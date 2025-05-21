locals {
  # Helper to transform the list of objects into a map keyed by stream_id for for_each
  datastream_map = {
    for config in var.datastream_configs : config.stream_id => config
  }
}

resource "google_datastream_stream" "streams" {
  for_each = local.datastream_map

  provider     = google-beta # Ensure you are using a provider alias that supports Datastream if necessary
  project      = var.project_id # Assuming you have a project_id variable defined elsewhere
  location     = each.value.location
  stream_id    = each.value.stream_id
  display_name = each.value.display_name

  source_config {
    source_connection_profile = each.value.source_connection_profile
    postgresql_source_config {
      include_objects {
        dynamic "postgresql_schemas" {
          for_each = each.value.postgres_include_schemas
          content {
            schema = postgresql_schemas.value.schema
            dynamic "postgresql_tables" {
              for_each = postgresql_schemas.value.tables
              content {
                table   = postgresql_tables.value.table_name
                dynamic "postgresql_columns" {
                  for_each = postgresql_tables.value.columns != null ? postgresql_tables.value.columns : []
                  content {
                    column = postgresql_columns.value
                  }
                }
              }
            }
          }
        }
      }
      dynamic "exclude_objects" {
        for_each = each.value.postgres_exclude_objects != null ? each.value.postgres_exclude_objects : []
        content {
          postgresql_schemas {
            schema = exclude_objects.value.schema
            dynamic "postgresql_tables" {
              for_each = exclude_objects.value.tables != null ? exclude_objects.value.tables : []
              content {
                table = postgresql_tables.value
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
      source_hierarchy_datasets {
        dataset_template {
          location       = each.value.bq_dataset_location
          dataset_id_prefix = each.value.bq_dataset_id_prefix
        }
      }
      data_freshness = each.value.bq_data_freshness // Example: 15 minutes, adjust as needed
    }
  }

  dynamic "backfill_all" {
    for_each = each.value.backfill_strategy == "all" ? [1] : []
    content {
    }
  }

  dynamic "backfill_none" {
    for_each = each.value.backfill_strategy == "none" ? [1] : []
    content {}
  }

  desired_state = each.value.run_immediately ? "RUNNING" : "NOT_STARTED"
}