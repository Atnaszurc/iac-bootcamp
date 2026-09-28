# ============================================================================
# Project Information
# ============================================================================

output "project_id" {
  description = "The GCP project ID"
  value       = var.project_id
}

output "region" {
  description = "The GCP region"
  value       = var.region
}

output "zone" {
  description = "The GCP zone"
  value       = var.zone
}

# ============================================================================
# IAM & Service Accounts
# ============================================================================

output "service_account_email" {
  description = "Email address of the service account"
  value       = google_service_account.app_sa.email
}

output "service_account_id" {
  description = "Unique ID of the service account"
  value       = google_service_account.app_sa.unique_id
}

output "custom_role_id" {
  description = "ID of the custom IAM role"
  value       = google_project_iam_custom_role.app_role.id
}

output "custom_role_permissions" {
  description = "Permissions granted by the custom role"
  value       = google_project_iam_custom_role.app_role.permissions
}

# ============================================================================
# Cloud KMS
# ============================================================================

output "kms_keyring_id" {
  description = "ID of the KMS key ring"
  value       = var.enable_kms ? google_kms_key_ring.keyring[0].id : null
}

output "kms_key_id" {
  description = "ID of the KMS crypto key"
  value       = var.enable_kms ? google_kms_crypto_key.key[0].id : null
}

output "kms_key_name" {
  description = "Name of the KMS crypto key"
  value       = var.enable_kms ? google_kms_crypto_key.key[0].name : null
}

output "kms_key_rotation_period" {
  description = "Rotation period of the KMS key"
  value       = var.enable_kms ? google_kms_crypto_key.key[0].rotation_period : null
}

# ============================================================================
# Cloud Storage
# ============================================================================

output "standard_bucket_name" {
  description = "Name of the standard storage bucket"
  value       = google_storage_bucket.standard.name
}

output "standard_bucket_url" {
  description = "URL of the standard storage bucket"
  value       = google_storage_bucket.standard.url
}

output "standard_bucket_self_link" {
  description = "Self link of the standard storage bucket"
  value       = google_storage_bucket.standard.self_link
}

output "encrypted_bucket_name" {
  description = "Name of the encrypted storage bucket"
  value       = var.enable_kms ? google_storage_bucket.encrypted[0].name : null
}

output "encrypted_bucket_url" {
  description = "URL of the encrypted storage bucket"
  value       = var.enable_kms ? google_storage_bucket.encrypted[0].url : null
}

output "uploaded_objects" {
  description = "List of uploaded object names"
  value       = [for obj in google_storage_bucket_object.sample_files : obj.name]
}

# ============================================================================
# Persistent Disks
# ============================================================================

output "standard_disk_id" {
  description = "ID of the standard persistent disk"
  value       = google_compute_disk.standard.id
}

output "standard_disk_self_link" {
  description = "Self link of the standard persistent disk"
  value       = google_compute_disk.standard.self_link
}

output "ssd_disk_id" {
  description = "ID of the SSD persistent disk"
  value       = google_compute_disk.ssd.id
}

output "ssd_disk_self_link" {
  description = "Self link of the SSD persistent disk"
  value       = google_compute_disk.ssd.self_link
}

output "encrypted_disk_id" {
  description = "ID of the encrypted persistent disk"
  value       = var.enable_kms ? google_compute_disk.encrypted[0].id : null
}

output "snapshot_id" {
  description = "ID of the disk snapshot"
  value       = google_compute_snapshot.backup.id
}

output "snapshot_self_link" {
  description = "Self link of the disk snapshot"
  value       = google_compute_snapshot.backup.self_link
}

# ============================================================================
# Secret Manager
# ============================================================================

output "secret_id" {
  description = "ID of the secret"
  value       = google_secret_manager_secret.app_secret.id
}

output "secret_name" {
  description = "Name of the secret"
  value       = google_secret_manager_secret.app_secret.secret_id
}

output "secret_version" {
  description = "Version of the secret"
  value       = google_secret_manager_secret_version.app_secret_v1.version
}

# ============================================================================
# Summary
# ============================================================================

output "infrastructure_summary" {
  description = "Summary of created infrastructure"
  value = {
    service_account = {
      email       = google_service_account.app_sa.email
      custom_role = google_project_iam_custom_role.app_role.id
    }
    kms = var.enable_kms ? {
      keyring = google_kms_key_ring.keyring[0].name
      key     = google_kms_crypto_key.key[0].name
    } : null
    storage = {
      standard_bucket  = google_storage_bucket.standard.name
      encrypted_bucket = var.enable_kms ? google_storage_bucket.encrypted[0].name : null
      objects_count    = length(google_storage_bucket_object.sample_files)
    }
    disks = {
      standard_disk  = google_compute_disk.standard.name
      ssd_disk       = google_compute_disk.ssd.name
      encrypted_disk = var.enable_kms ? google_compute_disk.encrypted[0].name : null
      snapshot       = google_compute_snapshot.backup.name
    }
    secrets = {
      secret_name = google_secret_manager_secret.app_secret.secret_id
      version     = google_secret_manager_secret_version.app_secret_v1.version
    }
  }
}

# ============================================================================
# Access Instructions
# ============================================================================

output "access_instructions" {
  description = "Instructions for accessing resources"
  value = <<-EOT
    
    === GCP-203 Security & Storage Resources ===
    
    Service Account:
      Email: ${google_service_account.app_sa.email}
      
    Cloud Storage:
      Standard Bucket: gs://${google_storage_bucket.standard.name}
      ${var.enable_kms ? "Encrypted Bucket: gs://${google_storage_bucket.encrypted[0].name}" : ""}
      
      List objects:
        gcloud storage ls gs://${google_storage_bucket.standard.name}
      
      Download object:
        gcloud storage cp gs://${google_storage_bucket.standard.name}/README.md .
    
    ${var.enable_kms ? <<-KMS
    Cloud KMS:
      Key Ring: ${google_kms_key_ring.keyring[0].name}
      Crypto Key: ${google_kms_crypto_key.key[0].name}
      
      Encrypt data:
        echo "sensitive data" | gcloud kms encrypt \
          --key=${google_kms_crypto_key.key[0].name} \
          --keyring=${google_kms_key_ring.keyring[0].name} \
          --location=${var.region} \
          --plaintext-file=- \
          --ciphertext-file=encrypted.bin
    KMS
: ""}
    
    Persistent Disks:
      Standard: ${google_compute_disk.standard.name}
      SSD: ${google_compute_disk.ssd.name}
      ${var.enable_kms ? "Encrypted: ${google_compute_disk.encrypted[0].name}" : ""}
      Snapshot: ${google_compute_snapshot.backup.name}
      
      List disks:
        gcloud compute disks list --filter="zone:${var.zone}"
      
      List snapshots:
        gcloud compute snapshots list
    
    Secret Manager:
      Secret: ${google_secret_manager_secret.app_secret.secret_id}
      
      Access secret:
        gcloud secrets versions access latest --secret=${google_secret_manager_secret.app_secret.secret_id}
    
    IAM:
      View service account permissions:
        gcloud projects get-iam-policy ${var.project_id} \
          --flatten="bindings[].members" \
          --filter="bindings.members:serviceAccount:${google_service_account.app_sa.email}"
      
      View custom role:
        gcloud iam roles describe ${google_project_iam_custom_role.app_role.role_id} --project=${var.project_id}
    
  EOT
}