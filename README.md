# Terraform Google Cloud Datastream (PostgreSQL to BigQuery)

## Overview

This Terraform configuration provisions and manages Google Cloud Datastream streams. It is specifically designed to replicate data from PostgreSQL source databases to Google BigQuery destinations.

## Prerequisites

Before using this Terraform configuration, ensure you have the following:

*   **Terraform**: Installed on your local machine. ([Installation Guide](https://learn.hashicorp.com/tutorials/terraform/install-cli))
*   **Google Cloud SDK**: Installed and authenticated. ([Installation Guide](https://cloud.google.com/sdk/docs/install))
    *   Ensure you have authenticated with `gcloud auth application-default login` or have a service account key configured.
*   **GCP APIs Enabled**: The following Google Cloud APIs must be enabled in your target project:
    *   Datastream API (`datastream.googleapis.com`)
    *   BigQuery API (`bigquery.googleapis.com`)
    *   Service Networking API (`servicenetworking.googleapis.com`) (if using Private Connectivity for Datastream)
*   **Permissions**: The authenticated principal (user or service account) must have sufficient IAM permissions to create and manage Datastream streams, connection profiles, and BigQuery datasets/tables in the specified project.

## Setup

1.  **Clone the repository** (if applicable) or ensure you have the Terraform files ([`main.tf`](main.tf:1), [`variables.tf`](variables.tf:1), [`terraform.tfvars.example`](terraform.tfvars.example:1)).
2.  **Create `terraform.tfvars`**:
    Copy the example variables file:
    ```bash
    cp terraform.tfvars.example terraform.tfvars
    ```
3.  **Populate `terraform.tfvars`**:
    Edit the [`terraform.tfvars`](terraform.tfvars:1) file and provide your specific values for the `project_id` and `datastream_configs`. Refer to the "Input Variables" section below for details on the structure of `datastream_configs`.

## Input Variables

The following input variables are defined in [`variables.tf`](variables.tf:1):

*   `project_id`
    *   Description: The Google Cloud Project ID where the Datastream resources will be created.
    *   Type: `string`
    *   Example: `"your-gcp-project-id"`

*   `datastream_configs`
    *   Description: A list of objects, where each object defines a Datastream stream configuration.
    *   Type: `list(object)`
    *   Attributes for each object in the list:
        *   `stream_id` (`string`): A unique identifier for the Datastream stream.
        *   `display_name` (`string`): A user-friendly name for the stream.
        *   `location` (`string`): The GCP region where the stream will be created (e.g., "us-central1").
        *   `source_connection_profile` (`string`): The full resource name of the pre-existing source PostgreSQL connection profile. Example: `projects/PROJECT_ID/locations/LOCATION/connectionProfiles/PROFILE_ID`
        *   `destination_connection_profile` (`string`): The full resource name of the pre-existing destination BigQuery connection profile. Example: `projects/PROJECT_ID/locations/LOCATION/connectionProfiles/PROFILE_ID`
        *   `publication_name` (`string`): The name of the PostgreSQL publication to stream changes from.
        *   `replication_slot_name` (`string`): The name of the PostgreSQL replication slot.
        *   `postgres_include_schemas` (`list(object)`): A list of PostgreSQL schemas to include. For each schema, specifies tables and their configurations for replication and BigQuery target table setup.
            *   `schema` (`string`): The PostgreSQL schema name.
            *   `tables` (`list(object)`, optional, default `[]`): List of tables to include from this schema. If this list is empty or omitted for a schema, Datastream's behavior for including all tables might apply, but explicit definition is recommended for clarity.
                *   `table_name` (`string`): The source PostgreSQL table name.
                *   `columns` (`list(string)`, optional): Specific source columns to include from the `table_name`. If empty or omitted, all columns from the source table are included.
                *   `target_table_name` (`string`, optional): Optional name for the target BigQuery table. If not specified, it defaults to the source `table_name`.
                *   `schema_fields` (`list(object)`): **Required.** Defines the schema for the target BigQuery table.
                    *   `name` (`string`): Name of the field in BigQuery.
                    *   `type` (`string`): Data type of the field (e.g., "STRING", "INTEGER", "TIMESTAMP", "NUMERIC", "BOOLEAN", "DATE").
                    *   `mode` (`string`, optional, default `"NULLABLE"`): Mode of the field (e.g., "NULLABLE", "REQUIRED", "REPEATED").
                    *   `description` (`string`, optional): A description for the field.
                *   `time_partitioning` (`object`, optional, default `null`): Configures time-based partitioning for the target BigQuery table.
                    *   `type` (`string`): The type of partitioning (e.g., "DAY", "HOUR", "MONTH", "YEAR").
                    *   `field` (`string`): The table field to use for partitioning. This field must be a top-level TIMESTAMP or DATE field.
                    *   `expiration_ms` (`number`, optional): Number of milliseconds for which to keep the storage for a partition.
                    *   `require_partition_filter` (`bool`, optional, default `false`): If `true`, queries over this table must include a partition filter.
                *   `clustering_fields` (`list(string)`, optional, default `null`): A list of up to four fields for BigQuery clustering for the target table.
        *   `postgres_exclude_objects` (`list(object)`, optional, default `[]`): A list of PostgreSQL schemas and specific tables within those schemas to exclude from replication.
            *   `schema` (`string`): The PostgreSQL schema name from which to exclude tables.
            *   `tables` (`list(string)`, optional, default `[]`): A list of table names within the specified `schema` to exclude. If this list is empty for a schema entry, no tables from this schema are explicitly excluded by this particular rule (the schema itself would need to be omitted from `postgres_include_schemas` to be fully excluded).
        *   `bq_dataset_id_prefix` (`string`): A prefix used for constructing BigQuery dataset IDs when Datastream is configured to create datasets based on the source schema hierarchy (e.g., "pg_replication_"). This prefix is used **only if** `bq_target_dataset_id` is `null` for the stream. The final dataset ID will be `[bq_dataset_id_prefix][source_schema_name]`.
        *   `bq_target_dataset_id` (`string`, optional, default `null`): The ID of a single, **pre-existing** BigQuery dataset where all tables from this stream will be replicated. If this is specified, `bq_dataset_id_prefix` is ignored for this stream, and Datastream will not attempt to create datasets based on source schema hierarchy. The module includes a data source to validate the existence of this dataset.
        *   `bq_dataset_location` (`string`): The location for BigQuery datasets (e.g., "US", "europe-west2"). This is primarily used when `bq_target_dataset_id` is `null`, and Datastream creates datasets using the `bq_dataset_id_prefix` and source schema name.
        *   `bq_data_freshness` (`string`, optional, default `"900s"`): The maximum staleness of data allowed for replication to BigQuery, specified as a duration string (e.g., "900s" for 15 minutes, "60m" for 1 hour).
        *   `backfill_strategy` (`string`, optional, default `"all"`): Determines the backfill strategy for the stream. Valid values are `"all"` (for historical data backfill) or `"none"` (to skip historical data).
        *   `run_immediately` (`bool`, optional, default `false`): If set to `true`, the stream will be created and immediately set to a "RUNNING" state. If `false`, the stream will be created in a "NOT_STARTED" state.

    Refer to [`terraform.tfvars.example`](terraform.tfvars.example:1) for the exact structure.

## Usage

1.  **Initialize Terraform**:
    Download necessary provider plugins.
    ```bash
    terraform init
    ```

2.  **Plan Changes**:
    Review the execution plan to see what resources Terraform will create, modify, or destroy.
    ```bash
    terraform plan
    ```

3.  **Apply Changes**:
    Create or update the infrastructure.
    ```bash
    terraform apply
    ```
    Enter `yes` when prompted to confirm.

4.  **Destroy Infrastructure**:
    Remove all resources managed by this Terraform configuration.
    ```bash
    terraform destroy
    ```
    Enter `yes` when prompted to confirm.

## Notes

*   **Stream State**: By default, streams are created in a "NOT_STARTED" state. To start them automatically upon creation, set the `run_immediately` attribute to `true` for the respective stream configuration in your [`terraform.tfvars`](terraform.tfvars:1) file. You can manually start, pause, or manage streams through the Google Cloud Console or `gcloud` CLI.
*   **Connection Profiles**: This Terraform configuration assumes that the source (PostgreSQL) and destination (BigQuery) connection profiles for Datastream already exist. You need to provide their full resource names in the `datastream_configs`.
*   **PostgreSQL Setup**: Ensure your PostgreSQL source is correctly configured for logical replication, including the creation of the specified `publication_name` and `replication_slot_name`.