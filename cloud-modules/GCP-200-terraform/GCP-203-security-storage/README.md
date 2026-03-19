# GCP-203: Security & Storage

**Level**: 203 (Intermediate - Cloud Specific)  
**Duration**: 2 hours  
**Prerequisites**: GCP-202 (Compute & Networking)  
**Status**: 🚧 **PLANNED** - Content in development

---

## 🎯 Learning Objectives

By the end of this module, you will be able to:

- ✅ Implement IAM roles and policies
- ✅ Create and manage service accounts
- ✅ Use Cloud Storage buckets effectively
- ✅ Manage persistent disks
- ✅ Implement encryption with Cloud KMS
- ✅ Configure Private Google Access
- ✅ Follow GCP security best practices
- ✅ Implement least privilege access

---

## 📚 Topics Covered

### 1. Identity and Access Management (IAM)
- IAM roles (primitive, predefined, custom)
- IAM policy bindings
- IAM conditions
- Service accounts
- Workload Identity
- IAM best practices
- Audit logging

### 2. Service Accounts
- Creating service accounts
- Service account keys
- Service account impersonation
- Workload Identity for GKE
- Short-lived credentials
- Service account best practices

### 3. Cloud Storage
- Bucket creation and configuration
- Storage classes (Standard, Nearline, Coldline, Archive)
- Bucket policies and IAM
- Object lifecycle management
- Versioning
- Retention policies
- Uniform bucket-level access
- Public access prevention

### 4. Persistent Disks
- Disk types (Standard, SSD, Balanced)
- Creating and attaching disks
- Disk snapshots
- Regional persistent disks
- Disk resizing
- Performance considerations

### 5. Encryption
- Encryption at rest (default)
- Customer-managed encryption keys (CMEK)
- Customer-supplied encryption keys (CSEK)
- Cloud KMS key management
- Key rotation
- Encryption best practices

### 6. Network Security
- Private Google Access
- VPC Service Controls
- Private Service Connect
- Cloud Armor
- Security Command Center

### 7. Secrets Management
- Secret Manager
- Storing and accessing secrets
- Secret versioning
- IAM for secrets

---

## 🛠️ Hands-On Labs

### Lab 1: IAM Roles and Policies
**Objective**: Implement proper IAM access control

**Steps**:
1. Create custom IAM role
2. Bind role to service account
3. Test permissions
4. Implement IAM conditions
5. Review audit logs

**Expected Outcome**: Properly configured IAM with least privilege

---

### Lab 2: Service Account Management
**Objective**: Create and use service accounts securely

**Steps**:
1. Create service account for application
2. Grant specific permissions
3. Generate short-lived credentials
4. Implement service account impersonation
5. Test access patterns

**Expected Outcome**: Secure service account configuration

---

### Lab 3: Cloud Storage Buckets
**Objective**: Create and configure Cloud Storage buckets

**Steps**:
1. Create bucket with appropriate storage class
2. Configure bucket policies
3. Implement lifecycle rules
4. Enable versioning
5. Upload and manage objects
6. Configure public access prevention

**Expected Outcome**: Production-ready Cloud Storage configuration

---

### Lab 4: Persistent Disk Management
**Objective**: Work with persistent disks

**Steps**:
1. Create persistent disk
2. Attach disk to instance
3. Format and mount disk
4. Create disk snapshot
5. Restore from snapshot
6. Resize disk

**Expected Outcome**: Understanding of disk lifecycle

---

### Lab 5: Encryption with Cloud KMS
**Objective**: Implement customer-managed encryption

**Steps**:
1. Create Cloud KMS key ring
2. Create encryption key
3. Grant KMS permissions
4. Encrypt Cloud Storage bucket with CMEK
5. Encrypt persistent disk with CMEK
6. Test key rotation

**Expected Outcome**: CMEK-encrypted resources

---

## 📖 Key Concepts

### IAM Role Types

| Type | Description | Example |
|------|-------------|---------|
| **Primitive** | Broad, legacy roles | Owner, Editor, Viewer |
| **Predefined** | Curated by Google | Compute Admin, Storage Admin |
| **Custom** | User-defined | Custom role with specific permissions |

### Storage Classes

| Class | Use Case | Minimum Storage | Retrieval Cost |
|-------|----------|-----------------|----------------|
| **Standard** | Frequently accessed | None | None |
| **Nearline** | < 1/month access | 30 days | Low |
| **Coldline** | < 1/quarter access | 90 days | Medium |
| **Archive** | < 1/year access | 365 days | High |

### Disk Types

| Type | IOPS | Throughput | Use Case |
|------|------|------------|----------|
| **pd-standard** | Low | Low | Batch processing |
| **pd-balanced** | Medium | Medium | General purpose |
| **pd-ssd** | High | High | Databases, high I/O |
| **pd-extreme** | Very High | Very High | Mission-critical |

---

## 💻 Example Code

### IAM Policy Binding

```hcl
# Service account
resource "google_service_account" "app_sa" {
  account_id   = "app-service-account"
  display_name = "Application Service Account"
  description  = "Service account for application workloads"
}

# Grant Compute Viewer role
resource "google_project_iam_member" "compute_viewer" {
  project = var.project_id
  role    = "roles/compute.viewer"
  member  = "serviceAccount:${google_service_account.app_sa.email}"
}

# Grant Storage Object Viewer role with condition
resource "google_storage_bucket_iam_member" "bucket_reader" {
  bucket = google_storage_bucket.data.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.app_sa.email}"
  
  condition {
    title       = "Expires in 2027"
    description = "Access expires at end of 2027"
    expression  = "request.time < timestamp('2027-12-31T23:59:59Z')"
  }
}

# Custom IAM role
resource "google_project_iam_custom_role" "app_role" {
  role_id     = "appCustomRole"
  title       = "Application Custom Role"
  description = "Custom role for application with specific permissions"
  
  permissions = [
    "compute.instances.get",
    "compute.instances.list",
    "storage.buckets.get",
    "storage.objects.get",
    "storage.objects.list",
  ]
}
```

### Cloud Storage Bucket

```hcl
# Cloud Storage bucket with lifecycle and versioning
resource "google_storage_bucket" "data" {
  name          = "my-data-bucket-${var.project_id}"
  location      = "US"
  storage_class = "STANDARD"
  
  # Uniform bucket-level access
  uniform_bucket_level_access {
    enabled = true
  }
  
  # Public access prevention
  public_access_prevention = "enforced"
  
  # Versioning
  versioning {
    enabled = true
  }
  
  # Lifecycle rules
  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }
  
  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type          = "SetStorageClass"
      storage_class = "COLDLINE"
    }
  }
  
  lifecycle_rule {
    condition {
      age                   = 365
      with_state            = "ARCHIVED"
      num_newer_versions    = 3
    }
    action {
      type = "Delete"
    }
  }
  
  # Labels
  labels = {
    environment = "production"
    managed_by  = "terraform"
  }
}

# Bucket object
resource "google_storage_bucket_object" "config" {
  name   = "config/app-config.json"
  bucket = google_storage_bucket.data.name
  source = "${path.module}/config.json"
  
  # Metadata
  metadata = {
    version = "1.0"
  }
}
```

### Persistent Disks

```hcl
# Standard persistent disk
resource "google_compute_disk" "data_disk" {
  name  = "data-disk"
  type  = "pd-standard"
  zone  = "us-central1-a"
  size  = 100  # GB
  
  labels = {
    environment = "production"
  }
}

# SSD persistent disk with snapshot schedule
resource "google_compute_disk" "ssd_disk" {
  name  = "ssd-disk"
  type  = "pd-ssd"
  zone  = "us-central1-a"
  size  = 50
  
  # Snapshot schedule
  snapshot_schedule_policy = google_compute_resource_policy.daily_snapshot.id
}

# Snapshot schedule policy
resource "google_compute_resource_policy" "daily_snapshot" {
  name   = "daily-snapshot-policy"
  region = "us-central1"
  
  snapshot_schedule_policy {
    schedule {
      daily_schedule {
        days_in_cycle = 1
        start_time    = "04:00"
      }
    }
    
    retention_policy {
      max_retention_days    = 14
      on_source_disk_delete = "KEEP_AUTO_SNAPSHOTS"
    }
    
    snapshot_properties {
      labels = {
        automated = "true"
      }
      storage_locations = ["us"]
      guest_flush       = false
    }
  }
}

# Attach disk to instance
resource "google_compute_attached_disk" "default" {
  disk     = google_compute_disk.data_disk.id
  instance = google_compute_instance.vm.id
}

# Disk snapshot
resource "google_compute_snapshot" "backup" {
  name        = "data-disk-backup"
  source_disk = google_compute_disk.data_disk.name
  zone        = google_compute_disk.data_disk.zone
  
  labels = {
    backup_type = "manual"
  }
}
```

### Cloud KMS Encryption

```hcl
# KMS key ring
resource "google_kms_key_ring" "keyring" {
  name     = "my-keyring"
  location = "us-central1"
}

# KMS crypto key
resource "google_kms_crypto_key" "key" {
  name     = "my-encryption-key"
  key_ring = google_kms_key_ring.keyring.id
  
  # Rotation period (90 days)
  rotation_period = "7776000s"
  
  lifecycle {
    prevent_destroy = true
  }
}

# Grant KMS permissions to service account
resource "google_kms_crypto_key_iam_member" "crypto_key" {
  crypto_key_id = google_kms_crypto_key.key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${google_service_account.app_sa.email}"
}

# Encrypt Cloud Storage bucket with CMEK
resource "google_storage_bucket" "encrypted_bucket" {
  name     = "encrypted-bucket-${var.project_id}"
  location = "US"
  
  encryption {
    default_kms_key_name = google_kms_crypto_key.key.id
  }
  
  depends_on = [google_kms_crypto_key_iam_member.crypto_key]
}

# Encrypt persistent disk with CMEK
resource "google_compute_disk" "encrypted_disk" {
  name  = "encrypted-disk"
  type  = "pd-ssd"
  zone  = "us-central1-a"
  size  = 50
  
  disk_encryption_key {
    kms_key_self_link = google_kms_crypto_key.key.id
  }
}
```

### Secret Manager

```hcl
# Enable Secret Manager API
resource "google_project_service" "secretmanager" {
  service = "secretmanager.googleapis.com"
}

# Create secret
resource "google_secret_manager_secret" "db_password" {
  secret_id = "database-password"
  
  replication {
    auto {}
  }
  
  labels = {
    environment = "production"
  }
  
  depends_on = [google_project_service.secretmanager]
}

# Add secret version
resource "google_secret_manager_secret_version" "db_password_v1" {
  secret = google_secret_manager_secret.db_password.id
  
  secret_data = var.db_password  # Should come from secure source
}

# Grant access to service account
resource "google_secret_manager_secret_iam_member" "secret_access" {
  secret_id = google_secret_manager_secret.db_password.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.app_sa.email}"
}
```

### Private Google Access

```hcl
# Subnet with Private Google Access enabled
resource "google_compute_subnetwork" "private_subnet" {
  name          = "private-subnet"
  ip_cidr_range = "10.0.1.0/24"
  region        = "us-central1"
  network       = google_compute_network.vpc.id
  
  # Enable Private Google Access
  private_ip_google_access = true
  
  # Secondary ranges for GKE (optional)
  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = "10.1.0.0/16"
  }
  
  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = "10.2.0.0/16"
  }
}

# Instance without external IP can access Google APIs
resource "google_compute_instance" "private_vm" {
  name         = "private-vm"
  machine_type = "e2-medium"
  zone         = "us-central1-a"
  
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }
  
  network_interface {
    subnetwork = google_compute_subnetwork.private_subnet.id
    # No access_config = no external IP
  }
  
  # Can still access Cloud Storage, etc. via Private Google Access
  metadata_startup_script = <<-EOF
    #!/bin/bash
    gsutil ls gs://my-bucket/
  EOF
}
```

---

## 🧪 Validation & Testing

### Verify IAM Permissions

```bash
# Test service account permissions
gcloud projects get-iam-policy PROJECT_ID \
  --flatten="bindings[].members" \
  --filter="bindings.members:serviceAccount:app-service-account@PROJECT_ID.iam.gserviceaccount.com"

# Test access as service account
gcloud auth activate-service-account --key-file=key.json
gcloud compute instances list
```

### Verify Cloud Storage

```bash
# List buckets
gsutil ls

# Check bucket IAM
gsutil iam get gs://bucket-name

# Upload test file
echo "test" > test.txt
gsutil cp test.txt gs://bucket-name/

# Verify lifecycle rules
gsutil lifecycle get gs://bucket-name
```

### Verify Disk Encryption

```bash
# Check disk encryption
gcloud compute disks describe DISK_NAME --zone=ZONE \
  --format="get(diskEncryptionKey)"
```

### Test Private Google Access

```bash
# SSH into private instance (via bastion or IAP)
gcloud compute ssh private-vm --zone=us-central1-a --tunnel-through-iap

# Test access to Google APIs
gsutil ls
gcloud compute instances list
```

---

## 🚨 Common Issues & Solutions

### Issue 1: "Permission denied" accessing bucket

**Error**: `AccessDeniedException: 403 Insufficient Permission`

**Solution**: Check IAM permissions, ensure service account has appropriate role

### Issue 2: "KMS key not found"

**Error**: `Error: The key does not exist`

**Solution**: Ensure KMS API is enabled and key exists in correct location

### Issue 3: "Cannot attach disk"

**Error**: `The disk resource 'projects/.../zones/.../disks/...' is already being used`

**Solution**: Disk can only be attached to one instance at a time

### Issue 4: "Private Google Access not working"

**Solution**: 
- Verify Private Google Access is enabled on subnet
- Check Cloud NAT is not interfering
- Verify DNS resolution

---

## 💡 Best Practices

### IAM Security
1. **Least privilege** - Grant minimum necessary permissions
2. **Use predefined roles** - Prefer over primitive roles
3. **Service accounts** - Use for applications, not user accounts
4. **Audit regularly** - Review IAM policies periodically
5. **Conditions** - Use IAM conditions for time-based or attribute-based access

### Storage Security
1. **Uniform bucket-level access** - Simplifies IAM management
2. **Public access prevention** - Enforce by default
3. **Versioning** - Enable for important data
4. **Lifecycle policies** - Automate data management
5. **Encryption** - Use CMEK for sensitive data

### Key Management
1. **Rotate keys** - Automate key rotation (90 days)
2. **Separate key rings** - By environment or application
3. **Prevent destroy** - Use lifecycle rules for keys
4. **Audit access** - Monitor key usage
5. **Backup keys** - Have recovery procedures

### Service Accounts
1. **Short-lived credentials** - Prefer over long-lived keys
2. **Workload Identity** - Use for GKE workloads
3. **Rotate keys** - If using keys, rotate every 90 days
4. **Minimal permissions** - Grant only what's needed
5. **Monitor usage** - Track service account activity

---

## 📚 Additional Resources

### Official Documentation
- [IAM Overview](https://cloud.google.com/iam/docs)
- [Cloud Storage](https://cloud.google.com/storage/docs)
- [Persistent Disks](https://cloud.google.com/compute/docs/disks)
- [Cloud KMS](https://cloud.google.com/kms/docs)
- [Secret Manager](https://cloud.google.com/secret-manager/docs)

### Terraform Resources
- [google_project_iam_member](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_project_iam_member)
- [google_storage_bucket](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket)
- [google_compute_disk](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_disk)
- [google_kms_crypto_key](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/kms_crypto_key)

---

## ✅ Module Completion Checklist

You've completed GCP-203 when you can:

- [ ] Configure IAM roles and policies
- [ ] Create and manage service accounts
- [ ] Work with Cloud Storage buckets
- [ ] Manage persistent disks and snapshots
- [ ] Implement encryption with Cloud KMS
- [ ] Use Secret Manager
- [ ] Configure Private Google Access
- [ ] Follow security best practices

---

## 🔄 What's Next?

After completing GCP-203, proceed to:

**→ [GCP-204: Advanced GCP Patterns](../GCP-204-advanced-patterns/README.md)**

Learn load balancing, autoscaling, and production-ready patterns.

---

*Part of [GCP-200: Google Cloud Platform with Terraform](../README.md)*  
*Last Updated: 2026-03-18*