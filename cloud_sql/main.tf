terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.0.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.db_region
}

resource "google_sql_database_instance" "main" {
  name             = var.db_name
  database_version = var.db_version
  project          = var.project_id
  region           = var.db_region

  settings {
    tier    = var.db_tier
    disk_size = var.db_disk_size
    edition = "ENTERPRISE"

    ip_configuration {
      psc_config {
        psc_enabled = true
        allowed_consumer_projects = [var.project_id]
        psc_auto_connections {
          consumer_network = var.consumer_network
          consumer_service_project_id = var.project_id
        }
      }
      ipv4_enabled = false
    }
    backup_configuration {
      enabled = true
      point_in_time_recovery_enabled = true
    }
    database_flags {
      name = "cloudsql.enable_pglogical"
      value = "on"
    }
    database_flags {
      name = "cloudsql.logical_decoding"
      value = "on"
    }
    database_flags {
      name = "temp_file_limit"
      value = "15728640"
    }
    availability_type = "ZONAL"
    insights_config {
      query_insights_enabled = true
    }
  }
}
resource "google_project_iam_member" "sql_sa_storage_admin" {
  project = var.project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_sql_database_instance.main.service_account_email_address}"
}