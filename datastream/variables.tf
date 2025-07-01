variable "project_id" {
  description = "The GCP project ID where resources will be deployed."
  type        = string
}

variable "datastream_configs" {
  description = "Configuration for multiple Datastream streams from PostgreSQL to BigQuery. Includes definitions for source objects and corresponding target BigQuery table schemas and configurations."
  type = list(object({
    stream_id          = string
    display_name       = string
    location           = string // Location of the Datastream stream resource itself, e.g., "us-central1"
    source_connection_profile = string // Full name: projects/{project}/locations/{location}/connectionProfiles/{name}
    destination_connection_profile = string // Full name: projects/{project}/locations/{location}/connectionProfiles/{name}
    publication_name               = string // Added: Per-stream publication name
    replication_slot_name          = string // Added: Per-stream replication slot name

    // PostgreSQL source specific details for include_objects
    postgres_include_schemas = list(object({
      schema = string // Schema name
      tables = optional(list(object({ // Tables to include from this schema. If empty/omitted, all tables from this schema are included.
        table_name        = string // Source PostgreSQL table name
        columns           = optional(list(string)) // Specific source columns to include. If empty/omitted, all columns.
        schema_fields     = list(object({      // Required: BigQuery schema definition for the target table.
          name = string
          type = string
          mode = optional(string, "NULLABLE")
          description = optional(string)
        }))
        table_constraints = optional(object({   // Optional: BigQuery time partitioning configuration.
          primary_key = optional(object({
            columns = list(string)
          }), null)
        }), null)
        time_partitioning = optional(object({   // Optional: BigQuery time partitioning configuration.
          type                       = string // e.g., "DAY", "HOUR", "MONTH", "YEAR"
          field                      = string // The field to use for partitioning.
          expiration_ms              = optional(number)
          require_partition_filter   = optional(bool, false)
        }), null)
        clustering_fields = optional(list(string), null) // Optional: List of fields for BigQuery clustering.
      })), [])
    }))

    max_concurrent_backfill_tasks = optional(number, 15)

    // PostgreSQL source specific details for exclude_objects
    postgres_exclude_objects = optional(list(object({
        schema = string // Schema name to exclude tables from
        tables = optional(list(string), []) // List of table names to exclude. If empty, no tables from this schema are explicitly excluded by this rule.
    })), [])

    // BigQuery destination specific details
    bq_dataset_id_prefix = string // Prefix for dataset IDs in BigQuery that Datastream will create/use, e.g., "pg_stream_". Not used if bq_target_dataset_id is set for a stream.
    bq_target_dataset_id = optional(string, null) // The ID of the single BigQuery dataset where all tables from this stream will be created. If specified, `bq_dataset_id_prefix` is ignored.
    
    bq_dataset_location  = string // Location for BQ datasets (used in source_hierarchy_datasets.dataset_template.location), e.g., "US"
    bq_data_freshness = optional(string, "900s") //Data Freshness for BQ, default to 900s
    // Stream behavior
    backfill_strategy = optional(string, "all") // Valid values: "all" or "none". Determines if backfill_all {} or backfill_none {} is set.
    run_immediately     = optional(bool, false)   // If true, stream is created with desired_state = "RUNNING". Default is "NOT_STARTED" (or "PAUSED" if created and then stopped).
  }))
}