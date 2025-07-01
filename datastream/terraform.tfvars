project_id = "project-sandbox-357505"

datastream_configs = [
  {
    # Sample Stream: PostgreSQL 'public.users' table to a partitioned BigQuery table
    stream_id                  = "test_transaction"
    display_name               = "Test transaction"
    location                   = "asia-southeast2" // TODO: Update to your desired Datastream location
    source_connection_profile  = "projects/project-sandbox-357505/locations/asia-southeast2/connectionProfiles/transact-private" // TODO: Update
    destination_connection_profile = "projects/project-sandbox-357505/locations/asia-southeast2/connectionProfiles/bq-out" // TODO: Update
    publication_name               = "transact_pub" // TODO: Ensure this publication exists on your PG source for the included tables
    replication_slot_name          = "transact_rep_slot" // TODO: Ensure this replication slot exists on your PG source

    postgres_include_schemas = [
      {
        schema = "public", // Source PostgreSQL schema
        tables = [
          {
            table_name = "transactions",                                        // Source PostgreSQL table name
            schema_fields = [ // BigQuery schema definition for the 'transaction' table
              { name = "transaction_id", type = "STRING", mode = "REQUIRED", description = "Primary key for the transaction (UUID)" },
              { name = "transaction_date", type = "DATE", mode = "NULLABLE", description = "Date and time of the transaction" },
              { name = "amount", type = "NUMERIC", mode = "NULLABLE", description = "Transaction amount" },
              { name = "item", type = "STRING", mode = "NULLABLE", description = "Item involved in the transaction" },
              { name = "channel", type = "STRING", mode = "NULLABLE", description = "Channel through which the transaction occurred" }
            ],
            table_constraints = {
              primary_key = {
                columns = ["transaction_id"]
              }
            }
            time_partitioning = { // BigQuery time partitioning configuration
              type  = "DAY",      // Partition by day
              field = "transaction_date",     // Partition on the 'date' BQ field
              require_partition_filter = true
            },
            # clustering_fields = ["item"] # Example: Cluster by the 'item' BQ field if desired
            clustering_fields = ["item","channel"]
          }
        ]
      }
    ]

    max_concurrent_backfill_tasks = 40

    # postgres_exclude_objects = [] # No excludes for this simple example
    
    bq_dataset_id_prefix = "ds_"
    # BigQuery Destination Configuration
    bq_target_dataset_id = null // TODO: Replace with your target BQ dataset ID. This dataset should exist or be managed elsewhere.
                                                       // If using prefix mode instead, set this to null and define bq_dataset_id_prefix.
    bq_dataset_location  = "asia-southeast2"                 // Should match the location of bq_target_dataset_id or where prefixed datasets will be created. TODO: Update if needed.
    bq_data_freshness    = "900s"                        // Data freshness (e.g., 15 minutes)
    backfill_strategy    = "all"
    run_immediately      = true
  }
]