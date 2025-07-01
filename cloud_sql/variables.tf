variable "project_id" {
  description = "The GCP project ID where resources will be deployed."
  type        = string
}

variable "db_name" {
  description = "The name of the Cloud SQL instance."
  type        = string
  default     = "datastream-test"
}

variable "db_version" {
  description = "The database version for the Cloud SQL instance."
  type        = string
  default     = "POSTGRES_15"
}

variable "db_tier" {
  description = "The machine type for the Cloud SQL instance."
  type        = string
  default     = "db-custom-4-8192"
}

variable "db_disk_size" {
  description = "The initial disk size for the Cloud SQL instance."
  type        = number
  default     = 30
}

variable "db_region" {
  description = "The region for the Cloud SQL instance."
  type        = string
  default     = "asia-southeast2"
}

variable "consumer_network" {
  description = "The consumer network for the Cloud SQL instance."
  type        = string
}