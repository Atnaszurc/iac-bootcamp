output "project_id" {
  description = "The GCP project ID"
  value       = var.project_id
}

output "project_number" {
  description = "The GCP project number"
  value       = data.google_project.current.number
}

output "region" {
  description = "The GCP region"
  value       = var.region
}

output "zone" {
  description = "The GCP zone"
  value       = var.zone
}

output "bucket_name" {
  description = "Name of the created Cloud Storage bucket"
  value       = google_storage_bucket.example.name
}

output "bucket_url" {
  description = "URL of the Cloud Storage bucket"
  value       = google_storage_bucket.example.url
}

output "bucket_self_link" {
  description = "Self link of the Cloud Storage bucket"
  value       = google_storage_bucket.example.self_link
}

output "enabled_apis" {
  description = "List of enabled APIs"
  value = [
    google_project_service.compute.service,
    google_project_service.storage.service
  ]
}