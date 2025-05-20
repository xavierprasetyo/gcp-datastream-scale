terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

resource "google_datastream_stream" "stream" {
  for_each = var.stream_configurations

  display_name  = each.value.display_name
  location      = "asia-southeast1" # Assuming location is static, or it can be added to stream_configurations
  stream_id     = each.key
  desired_state = "RUNNING"

    source_config {
        source_connection_profile = var.source_connection_profile_name
        postgresql_source_config {
            publication      = var.publication_name
            replication_slot = var.replication_slot_name
            dynamic "include_objects" {
              for_each = each.value.include_objects != null ? [each.value.include_objects] : []
              content {
                dynamic "postgresql_schemas" {
                  for_each = include_objects.value.postgresql_schemas
                  iterator = schema_item
                  content {
                    schema = schema_item.value.schema
                    dynamic "postgresql_tables" {
                      for_each = schema_item.value.postgresql_tables
                      iterator = table_item
                      content {
                        table = table_item.value.table
                        dynamic "postgresql_columns" {
                          for_each = table_item.value.postgresql_columns != null ? table_item.value.postgresql_columns : []
                          iterator = column_item
                          content {
                            column    = column_item.value.column
                            data_type = column_item.value.data_type
                          }
                        }
                      }
                    }
                  }
                }
              }
            }

            dynamic "exclude_objects" {
              for_each = each.value.exclude_objects != null ? [each.value.exclude_objects] : []
              content {
                dynamic "postgresql_schemas" {
                  for_each = exclude_objects.value.postgresql_schemas
                  iterator = schema_item
                  content {
                    schema = schema_item.value.schema
                    dynamic "postgresql_tables" {
                      for_each = schema_item.value.postgresql_tables
                      iterator = table_item
                      content {
                        table = table_item.value.table
                        dynamic "postgresql_columns" {
                          for_each = table_item.value.postgresql_columns != null ? table_item.value.postgresql_columns : []
                          iterator = column_item
                          content {
                            column    = column_item.value.column
                            data_type = column_item.value.data_type
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
        }
    }

    destination_config {
        destination_connection_profile = var.destination_connection_profile_name
        bigquery_destination_config {
            data_freshness = "900s"
            source_hierarchy_datasets {
                dataset_template {
                   location = "asia-southeast1"
                }
            }
        }
    }
}