# Terraform for Multiple Datastream Streams

This repository contains Terraform configurations to provision Google Cloud Datastream resources and a PSC-enabled Cloud SQL for PostgreSQL instance for testing purposes.

The primary feature of this configuration is its ability to define and manage multiple Datastream streams from a single, flexible configuration file, which dynamically creates the necessary BigQuery datasets and tables.

## Features

- **Multiple Datastream Streams**: Deploy and manage multiple streams with a single `terraform apply`.
- **Dynamic BigQuery Provisioning**:
    - Automatically create BigQuery datasets and tables based on your source database schema.
    - Two destination modes:
        1.  **Source Hierarchy**: Automatically create a separate BigQuery dataset for each PostgreSQL schema (e.g., `public` schema in PostgreSQL maps to `my_prefix_public` dataset in BigQuery).
        2.  **Single Target Dataset**: Consolidate all tables from a stream into a single, pre-existing BigQuery dataset.
- **Flexible Schema Definition**: Define source schemas, tables, and columns to include or exclude directly in your Terraform variables.
- **Automatic BigQuery Table Partitioning**: Configure time-partitioned and clustered tables directly in Terraform, avoiding manual setup in the GCP Console.
- **Test Environment**: Includes a standalone configuration to quickly spin up a PSC-enabled Cloud SQL for PostgreSQL instance to act as a source.

## Prerequisites

- [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli) installed.
- A Google Cloud Platform project.
- Authenticated `gcloud` CLI or a Service Account key with necessary permissions (Datastream Admin, BigQuery Admin, Cloud SQL Admin).

---

## 1. (Optional) Deploy Cloud SQL for Testing

This module sets up a Cloud SQL for PostgreSQL instance with Private Service Connect (PSC) enabled, which is ideal for testing Datastream from a private network.

1.  **Navigate to the Cloud SQL directory:**
    ```sh
    cd cloud_sql
    ```

2.  **Configure your environment:**
    Create a `terraform.tfvars` file by copying the example:
    ```sh
    cp terraform.tfvars.example terraform.tfvars
    ```
    Edit `terraform.tfvars` and provide values for your `project_id` and the `consumer_network`.

3.  **Deploy the instance:**
    ```sh
    terraform init
    terraform plan
    terraform apply
    ```

---

## 2. Deploy Datastream Streams

This is the core module for creating one or more Datastream streams.

### Understanding the Configuration

The main power of this module lies in the `datastream_configs` variable (defined in `datastream/variables.tf`). It is a list of objects, where each object represents a complete Datastream stream. This allows you to define all your streams in one place.

### Configuration Modes for BigQuery Destination

You can control where Datastream lands your data using one of two modes for each stream:

1.  **`source_hierarchy_datasets` (using `bq_dataset_id_prefix`)**:
    - You provide a prefix (e.g., `"pg_prod_"`).
    - Terraform will instruct Datastream to create a new BigQuery dataset for each source schema, combining your prefix and the schema name (e.g., `pg_prod_public`, `pg_prod_sales`).
    - The BigQuery tables are created by this Terraform module inside those datasets.
    - To use this mode, set `bq_dataset_id_prefix` and leave `bq_target_dataset_id` as `null`.

2.  **`single_target_dataset` (using `bq_target_dataset_id`)**:
    - You specify the exact ID of a **pre-existing** BigQuery dataset.
    - All tables from the stream will be created by this Terraform module in that single dataset.
    - To use this mode, set `bq_target_dataset_id` to your dataset ID. `bq_dataset_id_prefix` will be ignored.

### Automatic BigQuery Table Partitioning and Clustering

A key feature of this module is the ability to pre-define BigQuery table structures, including partitioning and clustering, directly within your Terraform configuration. This ensures that when Datastream replicates data, the destination tables are already optimized for queries, without needing manual intervention in the BigQuery console.

You can define the following for each table:

-   **`time_partitioning`**: Create a time-unit column-partitioned table.
    -   `field`: The name of the column to use for partitioning (must be a `TIMESTAMP` or `DATE` type).
    -   `type`: The partitioning type (`DAY`, `HOUR`, `MONTH`, or `YEAR`).
-   **`clustering_fields`**: A list of column names to cluster the table by.

This is configured within the `tables` object for each schema, as shown in the example below.

### Steps to Deploy

1.  **Navigate to the Datastream directory:**
    ```sh
    cd datastream
    ```

2.  **Configure your streams:**
    Create a `terraform.tfvars` file. Below is an example demonstrating how to create two streams with different configurations.

    ```hcl
    # terraform.tfvars

    project_id = "your-gcp-project-id"

    datastream_configs = [
      {
        # Stream 1: Replicates the 'public' schema to a prefixed dataset
        stream_id                      = "stream-for-public-schema"
        display_name                   = "Stream for Public Schema"
        location                       = "us-central1"
        source_connection_profile      = "projects/your-gcp-project-id/locations/us-central1/connectionProfiles/your-source-profile"
        destination_connection_profile = "projects/your-gcp-project-id/locations/us-central1/connectionProfiles/your-dest-profile"
        publication_name               = "tf_publication_1"
        replication_slot_name          = "tf_replication_slot_1"

        # Use prefix mode for BigQuery datasets
        bq_dataset_id_prefix = "ds_public_"
        bq_dataset_location  = "US"

        postgres_include_schemas = [
          {
            schema = "public"
            tables = [
              {
                table_name = "users"
                # Define the BigQuery schema for the 'users' table
                schema_fields = [
                  { name = "id", type = "INTEGER" },
                  { name = "email", type = "STRING" },
                  { name = "created_at", type = "TIMESTAMP" }
                ]
                time_partitioning = {
                  type  = "DAY"
                  field = "created_at"
                }
              },
              {
                table_name = "orders"
                schema_fields = [
                  { name = "order_id", type = "INTEGER" },
                  { name = "user_id", type = "INTEGER" },
                  { name = "amount", type = "FLOAT" }
                ]
              }
            ]
          }
        ]
      },
      {
        # Stream 2: Replicates the 'inventory' schema to a single target dataset
        stream_id                      = "stream-for-inventory"
        display_name                   = "Stream for Inventory"
        location                       = "us-central1"
        source_connection_profile      = "projects/your-gcp-project-id/locations/us-central1/connectionProfiles/your-source-profile"
        destination_connection_profile = "projects/your-gcp-project-id/locations/us-central1/connectionProfiles/your-dest-profile"
        publication_name               = "tf_publication_2"
        replication_slot_name          = "tf_replication_slot_2"

        # Use single target dataset mode
        bq_target_dataset_id = "existing_inventory_dataset"
        bq_dataset_location  = "US" # Still required by the variable, but used differently

        postgres_include_schemas = [
          {
            schema = "inventory"
            tables = [
              {
                table_name = "products"
                schema_fields = [
                  { name = "product_id", type = "STRING" },
                  { name = "name", type = "STRING" },
                  { name = "stock", type = "INTEGER" }
                ]
                clustering_fields = ["name"]
              }
            ]
          }
        ]
        # Exclude a specific table from the 'inventory' schema
        postgres_exclude_objects = [
          {
            schema = "inventory",
            tables = ["products_temp"]
          }
        ]
      }
    ]
    ```

3.  **Deploy the streams:**
    ```sh
    terraform init
    terraform plan
    terraform apply
    ```
