terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "5.37.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region = var.project_region
}

resource "google_sql_database_instance" "postgres-database-instance" {
  database_version = var.database_type
  name = var.database_instance_name
  region = var.project_region

  settings {
    tier = var.machine_type
    availability_type = var.availability_type
    edition = var.edition
    user_labels = {
      environment: var.environment
    }

  }

  deletion_protection = false
}


resource "google_sql_user" "users" {
  instance = google_sql_database_instance.postgres-database-instance.name
  name     = var.USER_NAME
  password = var.PASSWORD
}

resource "google_sql_database" "database" {
  instance = google_sql_database_instance.postgres-database-instance.name
  name     = var.database_name
}