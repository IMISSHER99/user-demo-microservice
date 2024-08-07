project_id = "capable-mind-428017-c2"
project_region = "asia-south1"
database_type = "POSTGRES_15"
database_instance_name = "postgres-database-instance"
machine_type = "db-f1-micro"
availability_type = "ZONAL"
edition = "ENTERPRISE"
environment = "development"
database_name = "postgres-database"
vpc_name = "microservice-vpc-network"
route_mode = "REGIONAL"
subnet_name = "microservice-subnet"
ip_address_range = "192.168.0.0/28"
stack_type = "IPV4_ONLY"
aggregate_interval = "INTERVAL_5_SEC"
include_all_metadata = "INCLUDE_ALL_METADATA"
allow_traffic_to_cloud_sql = "allow-traffic-to-cloud-sql"
protocol = "tcp"
cloud_sql_port = "5432"
http_port = "80"
https_port = "443"
allow_traffic_to_gke = "allow-traffic-to-gke"
cloud_sql_private_ip = "private-ip-alloc"
private_ip_type = "INTERNAL"
private_ip_purpose = "VPC_PEERING"
service_type = "servicenetworking.googleapis.com"
kubernetes_cluster = "kubernetes-cluster"
kubernetes_node_pool = "kubernetes-node-pool"
service_account = "dummy-524@capable-mind-428017-c2.iam.gserviceaccount.com"
kubernetes_machine_type = "e2-medium"
kubernetes_oauth_scope = "https://www.googleapis.com/auth/cloud-platform"
kubernetes_private_ip_range = "192.168.0.16/28"
kubernetes_network_provider = "CALICO"
artifact_repository_format = "DOCKER"
artifact_repository_cleanup_policy_id = "cleanup-policy"
ARTIFACT_REPOSITORY_ID = "microservice-artifact-registry"
