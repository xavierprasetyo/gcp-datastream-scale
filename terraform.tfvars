# ##############################################################################
# IMPORTANT: PLEASE REPLACE PLACEHOLDER VALUES!
# ##############################################################################
#
# This file contains example values. You MUST replace them with your actual
# configuration details before applying this Terraform configuration.
# Review each variable carefully and update it according to your environment
# and requirements.
#
# ##############################################################################
# Example values for variables defined in variables.tf

# The name of the source connection profile.
# Replace with your actual source connection profile name.
source_connection_profile_name = "projects/your-gcp-project/locations/your-region/connectionProfiles/your-source-profile"

# The name of the destination connection profile.
# Replace with your actual destination connection profile name.
destination_connection_profile_name = "projects/your-gcp-project/locations/your-region/connectionProfiles/your-destination-profile"

# The name of the publication in your source database.
# This is relevant for PostgreSQL sources.
publication_name = "your_db_publication_name"

# The name of the replication slot in your source database.
# This is relevant for PostgreSQL sources.
replication_slot_name = "your_db_replication_slot_name"

# A map of Datastream stream configurations.
# Each configuration defines a stream with its specific include/exclude objects.
#
# The 'stream_configurations' variable allows you to define multiple streams.
# Each key in the map (e.g., "example_stream_1") is a logical name for the stream configuration,
# and its value is an object defining the stream's properties.
#
# Properties for each stream configuration:
#   - display_name: A user-friendly name for the stream.
#   - stream_id_suffix: A suffix to be appended to the stream ID, making it unique.
#   - include_objects: (Optional) Defines which database objects (schemas, tables, columns) to include in the stream.
#     - postgresql_schemas: A list of schemas to include.
#       - schema: The name of the schema.
#       - postgresql_tables: A list of tables within this schema to include.
#         - table: The name of the table.
#         - postgresql_columns: (Optional) A list of specific columns to include from this table.
#           - column: The name of the column.
#           - data_type: (Optional) The data type of the column (e.g., "VARCHAR", "NUMERIC").
#   - exclude_objects: (Optional) Defines which database objects to exclude from the stream.
#     The structure is similar to 'include_objects'. If set to 'null', no objects are explicitly excluded.
#
# Note: If 'postgresql_tables' is omitted for a schema in 'include_objects', all tables in that schema are included.
# If 'postgresql_columns' is omitted for a table, all columns in that table are included.

stream_configurations = {
  "example_stream_1" = {
    display_name     = "Example Stream One - Specific Tables and Columns"
    stream_id_suffix = "stream1"
    include_objects = {
      postgresql_schemas = [
        {
          schema = "public" # Include from 'public' schema
          postgresql_tables = [
            {
              table = "orders" # Include the 'orders' table
              postgresql_columns = [ # Specifically include these columns from 'orders'
                { column = "order_id" },
                { column = "order_date" },
                { column = "customer_id" },
                { column = "total_amount", data_type = "NUMERIC" } # Optional: specify data_type
              ]
            },
            {
              table = "inventory" # Include the 'inventory' table (all columns)
            }
          ]
        },
        {
          schema = "sales" # Include from 'sales' schema
          postgresql_tables = [
            { table = "transactions" } # Include the 'transactions' table (all columns)
          ]
        }
      ]
    }
    exclude_objects = { # Example of excluding specific objects
      postgresql_schemas = [
        {
          schema = "public"
          postgresql_tables = [
            { table = "temporary_staging_table" } # Exclude this specific table
          ]
        }
      ]
    }
  },
  "example_stream_2" = {
    display_name     = "Example Stream Two - All Tables in Public Schema"
    stream_id_suffix = "stream2"
    include_objects = {
      postgresql_schemas = [
        {
          schema = "public" # Include all tables and all columns from the 'public' schema
          # No 'postgresql_tables' means all tables in 'public' are included.
        }
      ]
    }
    exclude_objects = null # No objects explicitly excluded for this stream
  },
  "example_stream_3" = {
    display_name     = "Example Stream Three - Specific Columns from a Table"
    stream_id_suffix = "stream3"
    include_objects = {
      postgresql_schemas = [
        {
          schema = "marketing"
          postgresql_tables = [
            {
              table = "campaigns"
              postgresql_columns = [
                { column = "campaign_id" },
                { column = "campaign_name" },
                { column = "start_date" },
                { column = "end_date" }
              ]
            }
          ]
        }
      ]
    }
    # exclude_objects is optional, if omitted or null, nothing is excluded by default.
  }
}