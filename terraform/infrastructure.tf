terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "5.37.0"
    }
  }
  # Setup backend to store the state files
  # In this case i am storing it in google compute storage
  backend "gcs" {
    bucket = "terraform-bucket-github-actions"
    prefix = "terraform/state"
  }
}

provider "google" {
  project = var.project_id
  region = var.project_region
}

# Creating a custom VPC
resource "google_compute_network" "custom_vpc_network" {
  name = var.vpc_name
  project = var.project_id
  auto_create_subnetworks = false
  # Maximum number of bytes that can be transferred through the network
  # including the header.
  mtu = 1460
  routing_mode = var.route_mode
}

# Creating a custom subnet
resource "google_compute_subnetwork" "custom_subnet" {
  ip_cidr_range = var.ip_address_range
  region        = var.project_region
  name          = var.subnet_name
  network       = google_compute_network.custom_vpc_network.name
  private_ip_google_access = true
  stack_type = var.stack_type
  depends_on = [google_compute_network.custom_vpc_network]

  log_config {
    aggregation_interval = var.aggregate_interval
    flow_sampling = 0.5
    metadata = var.include_all_metadata

  }
}

# Create custom firewall rules to allow communication to cloud SQL
resource "google_compute_firewall" "allow_traffic_to_cloud_sql" {
  name    = var.allow_traffic_to_cloud_sql
  network = google_compute_network.custom_vpc_network.name
  allow {
    protocol = var.protocol
    ports = [var.cloud_sql_port]
  }

  source_tags = [var.allow_traffic_to_cloud_sql]
}

# Create custom firewall rules to allow communication to GKE
resource "google_compute_firewall" "allow_traffic_to_gke" {
  name    = var.allow_traffic_to_gke
  network = google_compute_network.custom_vpc_network.name
  allow {
    protocol = var.protocol
    ports = [var.http_port, var.https_port]
  }

  source_tags = [var.allow_traffic_to_gke]
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
    ip_configuration {
      ipv4_enabled = true
      private_network = google_compute_network.custom_vpc_network.id
      enable_private_path_for_google_cloud_services = true
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