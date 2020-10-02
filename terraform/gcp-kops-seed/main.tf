provider "google" {}

variable "region" {
  default = "us-central1"
}

variable "environment" {
  default = "dev"
}

variable "project" {
  default = "project"
}

variable "domain" {
  default = "dev.project.com."
}

data "google_storage_project_service_account" "gcs_account" {}
data "google_project" "current" {}

resource "google_container_registry" "registry" {
  location = "US"
}

resource "google_storage_bucket_iam_member" "viewer" {
  bucket = google_container_registry.registry.id
  role   = "roles/storage.admin"
  member = "serviceAccount:${google_service_account.service_account.email}"
}

resource "google_storage_bucket_iam_member" "editor" {
  bucket = google_container_registry.registry.id
  role   = "roles/storage.admin"
  member = "serviceAccount:${google_service_account.service_gcr_account.email}"
}

resource "google_service_account" "service_gcr_account" {
  account_id   = "${var.region}-${var.environment}-${var.project}-gcr"
  display_name = "${var.project} GCR bot Service account for ${var.environment} in ${var.region}"
}

resource "google_service_account" "service_account" {
  account_id   = "${var.region}-${var.environment}-${var.project}-k8s"
  display_name = "${var.project} Kops Node Service account for ${var.environment} in ${var.region}"
}

resource "google_storage_bucket_iam_member" "member" {
  bucket = google_storage_bucket.kops-state.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.service_account.email}"
}

resource "google_project_iam_member" "view-secrets" {
  role   = "roles/secretmanager.secretAccessor"
  member = "serviceAccount:${google_service_account.service_account.email}"
}

resource "google_project_iam_member" "editor" {
  role   = "roles/editor"
  member = "serviceAccount:${google_service_account.service_account.email}"
}

resource "google_dns_managed_zone" "infra-zone" {
  name        = "${var.region}-${var.environment}-${var.project}"
  dns_name    = var.domain
  description = "Kops DNS"
}

resource "google_project_iam_member" "grant-google-storage-service-encrypt-decrypt" {
  role   = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member = "serviceAccount:service-${data.google_project.current.number}@gs-project-accounts.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "grant-google-storage-service-encrypt-decrypt-kops" {
  role   = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member = "serviceAccount:${google_service_account.service_account.email}"
}

resource "google_kms_crypto_key" "gcs" {
  name            = "gcs-key-kops"
  key_ring        = google_kms_key_ring.gcs.id
  rotation_period = "86401s"
}

resource "google_kms_key_ring" "gcs" {
  name     = "gcs-key-kops"
  location = "us"
}

resource "google_kms_crypto_key_iam_binding" "binding" {
  crypto_key_id = google_kms_crypto_key.gcs.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"

  members = ["serviceAccount:${data.google_storage_project_service_account.gcs_account.email_address}"]
}



resource "google_storage_bucket" "kops-state" {
  name = "${var.region}-${var.environment}-${var.project}-state"
  encryption {
    default_kms_key_name = google_kms_crypto_key.gcs.id
  }
  versioning {
    enabled = true
  }
  lifecycle {
    prevent_destroy = true
  }
  depends_on = [google_kms_crypto_key_iam_binding.binding]
}
