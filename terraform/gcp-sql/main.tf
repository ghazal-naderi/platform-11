variable "project" {}
variable "region" { default = "us-central1"}
variable "database_version" { default = "POSTGRES_11" }
variable "database_tier" { default = "db-f1-micro" }
variable "disk_size" { default = "10" }
provider "google" {}

data "google_compute_network" "private_network" {
  name = "default"
}

resource "random_id" "db_name_suffix" {
  byte_length = 4
}

resource "random_password" "password" {
  length = 16
  min_lower = 3
  min_special = 3
  min_numeric = 3
  min_upper = 3
  special = true
  override_special = "_%@"
}

resource "google_compute_global_address" "private_ip_address" {
  name          = "private-ip-address"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = data.google_compute_network.private_network.id
}

resource "google_sql_user" "users" {
  name     = "${var.project}_admin"
  instance = google_sql_database_instance.instance.name
  password = random_password.password.result
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = data.google_compute_network.private_network.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}

resource "google_sql_database_instance" "instance" {
  name             = "${var.project}-${random_id.db_name_suffix.hex}"
  database_version = var.database_version
  region           = var.region 

  depends_on = [google_service_networking_connection.private_vpc_connection]

  settings {
    availability_type = "REGIONAL"
    tier              = var.database_tier
    disk_size         = var.disk_size
    ip_configuration {
      ipv4_enabled    = false
      private_network = data.google_compute_network.private_network.id
    }
    backup_configuration {
      enabled = true
    }
  }
}

