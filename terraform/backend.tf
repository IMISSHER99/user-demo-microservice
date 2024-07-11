terraform {
  backend "gcs" {
    bucket = "terraform-bucket-github-actions"
    prefix = "terraform/state"
  }
}
