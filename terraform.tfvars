project_id = "your-gcp-project-id" // TODO: Replace with your actual GCP project ID

datastream_configs = [
  {
    stream_id                  = "pg-to-bq-stream-01" // TODO: Adjust stream_id if needed
    display_name               = "PostgreSQL to BigQuery Stream 1 (Sales Data)" // TODO: Adjust display_name
    location                   = "asia-southeast1" // TODO: Replace with your desired Datastream stream location
    source_connection_profile  = "projects/your-gcp-project-id/locations/us-central1/connectionProfiles/pg-source-profile-example" // TODO: Replace with your actual source connection profile path
    destination_connection_profile = "projects/your-gcp-project-id/locations/us-central1/connectionProfiles/bq-destination-profile-example" // TODO: Replace with your actual destination connection profile path
    publication_name               = "your_pg_publication_for_stream_1", // TODO: Replace with actual publication name for this stream
    replication_slot_name          = "your_pg_slot_for_stream_1",      // TODO: Replace with actual replication slot name for this stream

    postgres_include_schemas = [
      {
        schema = "sales", // TODO: Adjust schema name
        tables = [
          {
            table_name = "orders", // TODO: Adjust table name
            columns    = ["order_id", "customer_id", "order_date", "total_amount"] // TODO: Adjust columns or remove for all columns
          },
          {
            table_name = "customers" // TODO: Adjust table name (all columns will be included)
          }
        ]
      },
      {
        schema = "inventory" // TODO: Adjust schema name (all tables and columns will be included)
      }
    ]

    postgres_exclude_objects = [ // Optional: remove or adjust if not needed
      {
        schema = "sales", // TODO: Adjust schema name for exclusion
        tables = ["temporary_orders_archive"] // TODO: Adjust tables to exclude
      }
    ]

    bq_dataset_id_prefix = "sales_stream_" // TODO: Adjust BigQuery dataset ID prefix
    bq_dataset_location  = "asia-southeast1" // TODO: Replace with your desired BigQuery dataset location (e.g., "US", "EU")
    backfill_strategy    = "all" // Options: "all" or "none"
    run_immediately        = false // Options: true or false
  },
  {
    stream_id                  = "pg-to-bq-stream-02" // TODO: Adjust stream_id if needed
    display_name               = "PostgreSQL to BigQuery Stream 2 (Marketing Data - No Backfill)" // TODO: Adjust display_name
    location                   = "asia-southeast1" // TODO: Replace with your desired Datastream stream location
    source_connection_profile  = "projects/your-gcp-project-id/locations/us-east1/connectionProfiles/pg-source-profile-marketing" // TODO: Replace with your actual source connection profile path
    destination_connection_profile = "projects/your-gcp-project-id/locations/us-east1/connectionProfiles/bq-destination-profile-marketing" // TODO: Replace with your actual destination connection profile path
    publication_name               = "your_pg_publication_for_stream_2", // TODO: Replace with actual publication name for this stream
    replication_slot_name          = "your_pg_slot_for_stream_2",      // TODO: Replace with actual replication slot name for this stream

    postgres_include_schemas = [
      {
        schema = "marketing", // TODO: Adjust schema name
        tables = [
          {
            table_name = "campaigns" // TODO: Adjust table name
          },
          {
            table_name = "leads" // TODO: Adjust table name
          }
        ]
      }
    ]
    // No postgres_exclude_objects for this stream, so it's omitted (optional)

    bq_dataset_id_prefix = "mktg_stream_" // TODO: Adjust BigQuery dataset ID prefix
    bq_dataset_location  = "asia-southeast1" // TODO: Replace with your desired BigQuery dataset location
    backfill_strategy    = "all" // Options: "all" or "none"
    run_immediately      = false   // Options: true or false
  }
]