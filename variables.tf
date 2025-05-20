variable "source_connection_profile_name" {
  description = "The name of the source connection profile."
  type        = string
}

variable "destination_connection_profile_name" {
  description = "The name of the destination connection profile."
  type        = string
}
variable "publication_name" {
  description = "The name of the publication."
  type        = string
}

variable "replication_slot_name" {
  description = "The name of the replication slot."
  type        = string
}
variable "stream_configurations" {
  description = "A map of Datastream stream configurations. The keys of this map are the actual stream_ids that will be used for the GCP resources. Each configuration defines a stream with its specific include/exclude objects."
  type = map(object({
    display_name    = string
    include_objects = optional(object({
      postgresql_schemas = list(object({
        schema            = string
        postgresql_tables = list(object({
          table              = string
          postgresql_columns = optional(list(object({
            column    = string
            data_type = optional(string)
            # ordinal_position - (Optional) Column ordinal position.
            # primary_key - (Optional) Whether or not the column is a part of the primary key.
            # nullable - (Optional) Whether or not the column is nullable.
            # length - (Optional) Column length.
          })))
        }))
      }))
    }))
    exclude_objects = optional(object({
      postgresql_schemas = list(object({
        schema            = string
        postgresql_tables = list(object({
          table              = string
          postgresql_columns = optional(list(object({
            column    = string
            data_type = optional(string)
          })))
        }))
      }))
    }))
  }))
  default = {
    "example-stream-alpha" = { # Key is the stream_id
      display_name    = "Example Stream Alpha"
      include_objects = {
        postgresql_schemas = [
          {
            schema = "public"
            postgresql_tables = [
              { table = "orders" },
              { table = "customers" }
            ]
          }
        ]
      }
      exclude_objects = null
    },
    "example-stream-beta" = { # Key is the stream_id
      display_name    = "Example Stream Beta"
      include_objects = {
        postgresql_schemas = [
          {
            schema = "inventory"
            postgresql_tables = [
              {
                table = "products"
                postgresql_columns = [
                  { column = "id" },
                  { column = "name" },
                  { column = "price", data_type = "NUMERIC" }
                ]
              }
            ]
          }
        ]
      }
      exclude_objects = {
        postgresql_schemas = [
          {
            schema = "inventory"
            postgresql_tables = [
              { table = "product_logs" }
            ]
          }
        ]
      }
    }
  }
}