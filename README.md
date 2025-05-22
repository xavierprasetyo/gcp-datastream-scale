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
        *   `postgres_include_schemas` (`list(object)`): A list of PostgreSQL schemas, tables, and columns to include in the replication.
            *   `schema` (`string`): The PostgreSQL schema name.
            *   `tables` (`list(object)`): (Optional) List of tables within the schema.
                *   `table` (`string`): The PostgreSQL table name.
                *   `columns` (`list(object)`): (Optional) List of columns within the table.
                    *   `column` (`string`): The PostgreSQL column name.
                    *   `data_type` (`string`): (Optional) The data type of the column.
                    *   `nullable` (`bool`): (Optional) Whether the column is nullable.
                    *   `ordinal_position` (`number`): (Optional) The ordinal position of the column.
                    *   `primary_key` (`bool`): (Optional) Whether the column is part of the primary key.
        *   `postgres_exclude_objects` (`list(object)`): (Optional) A list of PostgreSQL schemas and tables to exclude from replication.
            *   `schema` (`string`): The PostgreSQL schema name.
            *   `tables` (`list(object)`): (Optional) List of tables within the schema to exclude.
                *   `table` (`string`): The PostgreSQL table name to exclude.
        *   `bq_dataset_id_prefix` (`string`): A prefix for the BigQuery dataset ID where the replicated data will be stored. The final dataset ID will be `bq_dataset_id_prefix_your_schema_name`.
        *   `bq_dataset_location` (`string`): The location for the BigQuery dataset (e.g., "US").
        *   `bq_data_freshness` (`string`): The maximum staleness of data that is allowed to be replicated to BigQuery (e.g., "900s" for 15 minutes).
        *   `backfill_strategy` (`string`, optional): The backfill strategy for the stream. Can be "all" or "none". Defaults to `"all"`.
        *   `run_immediately` (`bool`, optional): If set to `true`, the stream will be started immediately after creation. If `false`, the stream will be created in a "NOT_STARTED" state. Defaults to `false`.

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