terraform {
  backend "gcs" {
    bucket = "terraform-bucket-github-actions"
    prefix = "terraform/state"
    credentials = var.GOOGLE_CREDENTIALS
  }
}
