project_id = "your-gcp-project-id-here" // TODO: Replace with your actual GCP Project ID

datastream_configs = [
  {
    # Sample Stream: PostgreSQL 'public.users' table to a partitioned BigQuery table
    stream_id                  = "pg-users-to-bq-example"
    display_name               = "PostgreSQL Users to BigQuery Example"
    location                   = "us-central1" // TODO: Update to your desired Datastream location
    source_connection_profile  = "projects/your-gcp-project-id-here/locations/us-central1/connectionProfiles/your-pg-source-profile" // TODO: Update
    destination_connection_profile = "projects/your-gcp-project-id-here/locations/us-central1/connectionProfiles/your-bq-dest-profile" // TODO: Update
    publication_name               = "tf_example_pub_users" // TODO: Ensure this publication exists on your PG source for the included tables
    replication_slot_name          = "tf_example_slot_users" // TODO: Ensure this replication slot exists on your PG source

    postgres_include_schemas = [
      {
        schema = "public", // Source PostgreSQL schema
        tables = [
          {
            table_name = "users",                                        // Source PostgreSQL table name
            columns    = null,                                           // Include all columns from the source table
            target_table_name = "bq_users_partitioned",                  // Target BigQuery table name
            schema_fields = [                                            // BigQuery schema definition
              { name = "user_id", type = "INTEGER", mode = "REQUIRED", description = "Primary key for users" },
              { name = "username", type = "STRING", description = "User's login name" },
              { name = "email", type = "STRING", description = "User's email address" },
              { name = "created_at", type = "TIMESTAMP", description = "Timestamp of user creation" },
              { name = "last_login", type = "TIMESTAMP", description = "Timestamp of last user login" }
              // Datastream typically adds metadata columns like 'datastream_metadata'.
              // If you need to manage them via Terraform schema, define them here.
              // e.g., { name = "datastream_metadata", type = "RECORD", mode = "NULLABLE", fields = [
              //   { name = "uuid", type = "STRING" }, { name = "source_timestamp", type = "INTEGER" }
              // ]}
            ],
            time_partitioning = {                                        // BigQuery time partitioning configuration
              type  = "DAY",                                             // Partition by day
              field = "created_at",                                      // Partition on the 'created_at' BQ field
              require_partition_filter = true
            },
            clustering_fields = ["email"]                                // Cluster by the 'email' BQ field
          }
        ]
      }
    ]

    # postgres_exclude_objects = [] # No excludes for this simple example

    # BigQuery Destination Configuration
    bq_target_dataset_id = "example_datastream_output" // TODO: Replace with your target BQ dataset ID. This dataset should exist or be managed elsewhere.
                                                       // If using prefix mode instead, set this to null and define bq_dataset_id_prefix.
    bq_dataset_location  = "us-central1"                 // Should match the location of bq_target_dataset_id or where prefixed datasets will be created. TODO: Update if needed.
    bq_data_freshness    = "900s"                        // Data freshness (e.g., 15 minutes)
    backfill_strategy    = "all"
    run_immediately      = true
  }
]

# Note: Replace placeholder values (marked with TODO) with your actual configuration details.
# This file provides a basic runnable example. For more complex scenarios or multiple streams,
# refer to terraform.tfvars.example.