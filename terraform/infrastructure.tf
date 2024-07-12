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
  region  = var.project_region
}

# Creating a custom VPC
resource "google_compute_network" "custom-vpc-network" {
  name                    = var.vpc_name
  project                 = var.project_id
  auto_create_subnetworks = false
  mtu                     = 1460
  routing_mode            = var.route_mode
}

# Creating a custom subnet
resource "google_compute_subnetwork" "custom-subnet" {
  ip_cidr_range            = var.ip_address_range
  region                   = var.project_region
  name                     = var.subnet_name
  network                  = google_compute_network.custom-vpc-network.name
  private_ip_google_access = true
  stack_type               = var.stack_type

  log_config {
    aggregation_interval = var.aggregate_interval
    flow_sampling        = 0.5
    metadata             = var.include_all_metadata
  }
}

# Create custom firewall rules to allow communication to Cloud SQL
resource "google_compute_firewall" "allow-traffic-to-cloud-sql" {
  name    = var.allow_traffic_to_cloud_sql
  network = google_compute_network.custom-vpc-network.name
  allow {
    protocol = var.protocol
    ports    = [var.cloud_sql_port]
  }
  source_tags = [var.allow_traffic_to_cloud_sql]
}

# Create custom firewall rules to allow communication to GKE
resource "google_compute_firewall" "allow-traffic-to-gke" {
  name    = var.allow_traffic_to_gke
  network = google_compute_network.custom-vpc-network.name
  allow {
    protocol = var.protocol
    ports    = [var.http_port, var.https_port]
  }
  source_tags = [var.allow_traffic_to_gke]
}


# Create an IP address range for VPC peering
resource "google_compute_global_address" "private_ip_alloc" {
  name          = "private-ip-alloc"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 24
  network       = google_compute_network.custom-vpc-network.self_link
}

# Create or update a private services connection
resource "google_service_networking_connection" "private_connection" {
  network                = google_compute_network.custom-vpc-network.name
  service                = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_alloc.name]
}

resource "google_sql_database_instance" "postgres-database-instance" {
  database_version = var.database_type
  name             = var.database_instance_name
  region           = var.project_region
  depends_on       = [google_service_networking_connection.private_connection]


  settings {
    tier              = var.machine_type
    availability_type = var.availability_type
    edition           = var.edition
    user_labels       = {
      environment = var.environment
    }
    ip_configuration {
      ipv4_enabled      = true
      private_network   = google_compute_network.custom-vpc-network.id
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
