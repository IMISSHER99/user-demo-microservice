terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "5.37.0"
    }
  }
  backend "gcs" {
    bucket = "terraform-bucket-github-actions"
    prefix = "terraform/state"
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

# Create a kubernetes cluster
resource "google_container_cluster" "kubernetes_cluster" {
  name = var.kubernetes_cluster
  location = var.project_region
  remove_default_node_pool = true
  initial_node_count = 1
  deletion_protection = false
  network = google_compute_network.custom-vpc-network.name
  subnetwork = google_compute_subnetwork.custom-subnet.name

# Enable private cluster config
  private_cluster_config {
    enable_private_nodes = true
    enable_private_endpoint = false
    master_ipv4_cidr_block = var.kubernetes_private_ip_range
  }

# enable shielded nodes
  enable_shielded_nodes = true

# enable workload identity
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  network_policy {
    enabled = true
    provider = var.kubernetes_network_provider
  }


  node_config {
    service_account = var.service_account
    preemptible = true
    machine_type = var.kubernetes_machine_type
    oauth_scopes = [
      var.kubernetes_oauth_scope
    ]

    shielded_instance_config {
      enable_integrity_monitoring = true
      enable_secure_boot = true
    }
  }
# Not really needed as it defaults to that logging service
  logging_service = "logging.googleapis.com/kubernetes"
  monitoring_service = "monitoring.googleapis.com/kubernetes"
}

# create a node pool for the cluster
resource "google_container_node_pool" "node_pool" {
  cluster = google_container_cluster.kubernetes_cluster.name
  location = var.project_region
  name = var.kubernetes_node_pool
  node_count = 1

  node_config {
    service_account = var.service_account
    preemptible = true
    machine_type = var.kubernetes_machine_type
    oauth_scopes = [
      var.kubernetes_oauth_scope
    ]
  }
}

# Create an IP address range for VPC peering
resource "google_compute_global_address" "cloud_sql_private_ip" {
  name          = var.cloud_sql_private_ip
  purpose       = var.private_ip_purpose
  address_type  = var.private_ip_type
  prefix_length = 24
  network       = google_compute_network.custom-vpc-network.self_link
}

# Create or update a private services connection
resource "google_service_networking_connection" "private_service_connection" {
  network                = google_compute_network.custom-vpc-network.name
  service                = var.service_type
  reserved_peering_ranges = [google_compute_global_address.cloud_sql_private_ip.name]
  depends_on = [google_compute_global_address.cloud_sql_private_ip]

}

# Creating a cloud sql database instance
resource "google_sql_database_instance" "postgres-database-instance" {
  database_version = var.database_type
  name             = var.database_instance_name
  region           = var.project_region
  depends_on       = [google_service_networking_connection.private_service_connection]


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

# Creating a user for that instance
resource "google_sql_user" "users" {
  instance = google_sql_database_instance.postgres-database-instance.name
  name     = var.USER_NAME
  password = var.PASSWORD
}

# Creating a database
resource "google_sql_database" "database" {
  instance = google_sql_database_instance.postgres-database-instance.name
  name     = var.database_name
}

resource "google_artifact_registry_repository" "artifact_registry" {
  location = var.project_region
  repository_id = var.ARTIFACT_REPOSITORY_ID
  format = var.artifact_repository_format
  cleanup_policy_dry_run = false
  cleanup_policies {
    id = var.artifact_repository_cleanup_policy_id
    action = "DELETE"
    condition {
      tag_state = "ANY"
      older_than = "2592000s"
    }
  }
}