# GCP-200: Google Cloud Platform with Terraform

**Level**: 200 (Intermediate)  
**Duration**: 6 hours  
**Prerequisites**: TF-100 series (Terraform Fundamentals)  
**Platform**: Google Cloud Platform (GCP)  
**Status**: 🚧 **IN DEVELOPMENT** - Structure ready, content in progress

---

## 🎯 Course Overview

**GCP-200: Google Cloud Platform with Terraform** is an **optional cloud provider module** that teaches you how to apply the Terraform concepts you learned in the core training (TF-100, TF-200, TF-300) to Google Cloud Platform.

This course assumes you've completed the **core Libvirt-based training** and are now ready to work with a real cloud provider. All the concepts you learned (variables, modules, validation, etc.) apply directly to GCP—you're just using different resources.

---

## 📚 What You'll Learn

### Core Competencies

After completing GCP-200, you will be able to:

- ✅ **Configure GCP Provider**: Set up authentication and provider configuration
- ✅ **Create VPC Networks**: Build VPCs, subnets, and firewall rules
- ✅ **Deploy Compute Instances**: Launch and manage Compute Engine VMs
- ✅ **Implement Security**: Configure IAM, service accounts, and firewall rules
- ✅ **Manage Storage**: Work with Cloud Storage buckets and persistent disks
- ✅ **Use GCP Services**: Integrate Cloud SQL, Load Balancers, and more
- ✅ **Apply Core Concepts**: Use modules, validation, and patterns from core training

---

## 🗂️ Course Modules

### GCP-201: GCP Setup & Authentication
**Duration**: 1 hour  
**Directory**: `GCP-201-setup-auth/` **[PLANNED]**

Learn to configure GCP access and the Terraform Google provider.

**Topics** (Planned):
- GCP account and project setup
- Google Cloud SDK (gcloud) installation
- Service account creation for Terraform
- Authentication methods (service account keys, ADC)
- GCP provider configuration
- Project and region selection
- Best practices for GCP authentication
- Using Cloud Shell

**Hands-On** (Planned):
- Set up Google Cloud SDK
- Create GCP project
- Create service account for Terraform
- Configure authentication
- Write first GCP provider configuration
- Test GCP connectivity
- Configure multiple projects

---

### GCP-202: Compute & Networking
**Duration**: 2 hours  
**Directory**: `GCP-202-compute-networking/` **[PLANNED]**

Build GCP networking infrastructure and deploy Compute Engine instances.

**Topics** (Planned):
- VPC network creation (auto-mode vs custom)
- Subnets and IP address ranges
- Firewall rules and network tags
- Cloud NAT and Cloud Router
- Compute Engine instance types and machine families
- Custom images and public images
- Startup scripts and metadata
- SSH key management
- Instance templates
- Regional and zonal resources

**Hands-On** (Planned):
- Create custom VPC network
- Configure subnets across regions
- Set up firewall rules
- Deploy Compute Engine instances
- Configure Cloud NAT
- Use startup scripts
- Build multi-tier network architecture
- Implement instance templates

---

### GCP-203: Security & Storage
**Duration**: 2 hours  
**Directory**: `GCP-203-security-storage/` **[PLANNED]**

Implement GCP security best practices and manage storage resources.

**Topics** (Planned):
- IAM roles and policies
- Service accounts and workload identity
- IAM conditions and policy bindings
- Cloud Storage buckets and objects
- Bucket policies and ACLs
- Persistent disks (standard, SSD, balanced)
- Disk encryption (CMEK, CSEK)
- Cloud KMS for key management
- VPC Service Controls
- Private Google Access

**Hands-On** (Planned):
- Create and manage IAM roles
- Configure service accounts
- Set up Cloud Storage buckets
- Implement bucket policies
- Create and attach persistent disks
- Configure disk encryption
- Use Cloud KMS
- Implement least privilege access
- Configure Private Google Access

---

### GCP-204: Advanced GCP Patterns
**Duration**: 1 hour  
**Directory**: `GCP-204-advanced-patterns/` **[PLANNED]**

Implement advanced GCP patterns including load balancing, auto-scaling, and multi-region deployments.

**Topics** (Planned):
- Cloud Load Balancing (HTTP(S), TCP/SSL, Internal)
- Managed Instance Groups (MIGs)
- Autoscaling policies
- Health checks
- Cloud SQL (MySQL, PostgreSQL)
- Multi-region deployments
- Cloud CDN
- Cloud Armor (DDoS protection)
- Cloud Monitoring and Logging
- Production-ready patterns

**Hands-On** (Planned):
- Create HTTP(S) Load Balancer
- Configure Managed Instance Group
- Implement autoscaling
- Deploy Cloud SQL database
- Set up multi-region architecture
- Configure Cloud Monitoring
- Build production-ready infrastructure
- Implement Cloud Armor policies

---

## 🎓 Learning Path

### Recommended Progression

```
Prerequisites: Complete TF-100, TF-200, TF-300
└── You already know Terraform!

Week 1: GCP Fundamentals
├── Day 1: GCP-201 (Setup & Authentication)
├── Day 2-3: GCP-202 (Compute & Networking)
└── Day 4-5: GCP-203 (Security & Storage)

Week 2: Advanced GCP
└── Day 1-2: GCP-204 (Advanced Patterns)
    └── Practice: Build production infrastructure
```

### Why After Core Training?

This course assumes you already understand:
- ✅ Terraform syntax and workflow
- ✅ Variables, loops, and functions
- ✅ Module design and composition
- ✅ State management
- ✅ Validation and testing

You're just learning **GCP-specific resources**, not Terraform itself.

---

## 💰 Cost Considerations

### GCP Free Tier

GCP offers a generous free tier that includes:
- **$300 credit**: Valid for 90 days for new accounts
- **Always Free**: Continues after trial ends
  - **Compute Engine**: 1 f1-micro instance/month (US regions)
  - **Cloud Storage**: 5 GB standard storage
  - **Cloud Functions**: 2 million invocations/month
  - **Cloud Run**: 2 million requests/month
  - **BigQuery**: 1 TB queries/month, 10 GB storage
  - **Cloud Build**: 120 build-minutes/day

### Estimated Costs

If you stay within free tier limits:
- **Course Completion**: $0-5 (with $300 credit)
- **Practice Projects**: $5-20/month (after credit expires)

**Important**: Always clean up resources after practice to avoid charges!

### Cost Management Tips

1. **Use Free Tier**: Stay within always-free limits
2. **Clean Up**: Always destroy resources after practice
3. **Set Budgets**: Use GCP Budgets and Alerts
4. **Use f1-micro/e2-micro**: Smallest instance types
5. **Monitor Costs**: Check Cloud Billing regularly
6. **Use Preemptible VMs**: For non-critical workloads (up to 80% cheaper)
7. **Stop Instances**: Stop (don't delete) instances when not in use

---

## 🚀 Getting Started

### Prerequisites

Before starting GCP-200, you must have:

1. **Completed Core Training**:
   - ✅ TF-100: Terraform Fundamentals
   - ✅ TF-200: Terraform Modules & Patterns (recommended)
   - ✅ TF-300: Testing & Validation (optional but helpful)

2. **GCP Account**:
   - Google Cloud account (free tier eligible)
   - Credit card for account verification
   - Understanding of GCP billing

3. **Software**:
   - Terraform 1.14+
   - Google Cloud SDK (gcloud)
   - Text editor (VS Code recommended)

### Setup Steps

```bash
# 1. Create GCP account
# Visit: https://cloud.google.com/free

# 2. Install Google Cloud SDK
# Ubuntu/Debian
curl https://sdk.cloud.google.com | bash
exec -l $SHELL

# macOS
brew install --cask google-cloud-sdk

# Windows
# Download from: https://cloud.google.com/sdk/docs/install

# 3. Initialize gcloud
gcloud init

# 4. Create a new project
gcloud projects create my-terraform-project --name="Terraform Learning"

# 5. Set the project
gcloud config set project my-terraform-project

# 6. Enable required APIs
gcloud services enable compute.googleapis.com
gcloud services enable storage.googleapis.com
gcloud services enable iam.googleapis.com

# 7. Create service account for Terraform
gcloud iam service-accounts create terraform \
  --display-name="Terraform Service Account"

# 8. Grant necessary permissions
gcloud projects add-iam-policy-binding my-terraform-project \
  --member="serviceAccount:terraform@my-terraform-project.iam.gserviceaccount.com" \
  --role="roles/editor"

# 9. Create and download key
gcloud iam service-accounts keys create ~/terraform-key.json \
  --iam-account=terraform@my-terraform-project.iam.gserviceaccount.com

# 10. Set environment variable
export GOOGLE_APPLICATION_CREDENTIALS=~/terraform-key.json

# 11. Verify setup
gcloud auth application-default print-access-token

# 12. Navigate to course (when available)
cd hashi-training/cloud-modules/GCP-200-terraform
```

---

## 📖 Course Materials

### What Will Be Included

Each module will contain:

- **README.md**: Detailed explanations and learning objectives
- **example/**: Working Terraform configurations for GCP
- **Exercises**: Hands-on labs with GCP resources
- **Cost Estimates**: Expected costs for each exercise
- **Cleanup Scripts**: Ensure resources are destroyed

### Directory Structure

```
GCP-200-terraform/
├── README.md                          # This file
├── GCP-201-setup-auth/                # [PLANNED]
│   ├── README.md
│   └── example/
├── GCP-202-compute-networking/        # [PLANNED]
│   ├── README.md
│   └── example/
├── GCP-203-security-storage/          # [PLANNED]
│   ├── README.md
│   └── example/
└── GCP-204-advanced-patterns/         # [PLANNED]
    ├── README.md
    └── example/
```

---

## 🎯 Learning Objectives

### By Module

#### After GCP-201, you will:
- Set up GCP account and projects
- Configure Google Cloud SDK
- Create service accounts for Terraform
- Write GCP provider configurations
- Understand GCP authentication methods
- Work with multiple projects

#### After GCP-202, you will:
- Create custom VPC networks
- Configure subnets and firewall rules
- Deploy Compute Engine instances
- Configure Cloud NAT
- Build multi-tier network architectures
- Use instance templates

#### After GCP-203, you will:
- Create and manage IAM roles
- Configure service accounts
- Create Cloud Storage buckets
- Manage persistent disks
- Implement encryption with Cloud KMS
- Use Private Google Access
- Follow security best practices

#### After GCP-204, you will:
- Configure load balancers
- Implement Managed Instance Groups
- Set up autoscaling
- Deploy Cloud SQL databases
- Build multi-region infrastructure
- Configure Cloud Monitoring
- Build production-ready GCP infrastructure

---

## 🏆 Success Criteria

You've successfully completed GCP-200 when you can:

- [ ] Configure GCP provider and authentication
- [ ] Create VPC infrastructure from scratch
- [ ] Deploy Compute Engine instances with proper security
- [ ] Manage IAM roles and service accounts
- [ ] Configure Cloud Storage and persistent disks
- [ ] Implement load balancing and autoscaling
- [ ] Build production-ready GCP infrastructure
- [ ] Apply core Terraform concepts to GCP
- [ ] Manage GCP costs effectively

---

## 🔄 What's Next?

### After GCP-200

Once you complete GCP-200, you can:

1. **AWS-200: AWS with Terraform**
   - Learn AWS-specific resources
   - Compare GCP and AWS approaches
   - Build multi-cloud skills

2. **AZ-200: Azure with Terraform**
   - Learn Azure-specific resources
   - Compare GCP and Azure approaches
   - Build multi-cloud skills

3. **MC-300: Multi-Cloud Architecture**
   - Abstract cloud differences
   - Build cloud-agnostic modules
   - Implement multi-cloud patterns

4. **GCP Certifications**:
   - Google Cloud Associate Cloud Engineer
   - Google Cloud Professional Cloud Architect
   - Google Cloud Professional Cloud Developer

5. **Real-World Projects**:
   - Build production GCP infrastructure
   - Implement CI/CD pipelines
   - Create self-service platforms
   - Contribute to GCP modules

---

## 💡 Why This Course is Optional

### Core Training is Cloud-Agnostic

The core training (TF-100, TF-200, TF-300) teaches you:
- Terraform syntax and concepts
- Module design patterns
- Validation and testing
- Best practices

These concepts apply to **any** cloud provider or infrastructure platform.

### GCP-200 is Just Application

This course teaches you:
- GCP-specific resource types
- GCP provider configuration
- GCP best practices

You're **applying** what you already know to GCP resources.

### Choose Your Path

- **Core Only**: Learn Terraform without cloud costs
- **Core + AWS**: Apply to most popular cloud
- **Core + Azure**: Apply to enterprise cloud
- **Core + GCP**: Apply to Google's cloud
- **Core + Multi-Cloud**: Master multiple clouds

---

## ⚠️ GCP Provider v7.24.0 Features

All examples in this module use `hashicorp/google ~> 7.24.0`. Key features and considerations:

### New in v7.x Series

| Feature | Description | Status in Examples |
|---------|-------------|-------------------|
| **Compute Engine**: `advanced_machine_features` | Configure thread settings, NUMA nodes | ✅ Documented |
| **Cloud Storage**: `autoclass` | Automatic storage class transitions | ✅ Documented |
| **IAM**: `iam_deny_policy` | Deny policies for fine-grained access control | ✅ Documented |
| **VPC**: `internal_ipv6_prefix` | IPv6 support for internal networks | ✅ Documented |
| **Cloud SQL**: `deletion_protection_enabled` | Prevent accidental database deletion | ✅ Used in examples |
| **Compute Instance**: `network_performance_config` | Configure network bandwidth | ✅ Documented |

### Breaking Changes from v6.x

| Change | Impact | Migration Guide |
|--------|--------|-----------------|
| `google_project_service` — `disable_on_destroy` default changed to `false` | Services no longer disabled on destroy by default | Set explicitly if needed |
| `google_compute_instance` — `metadata_startup_script` deprecated | Use `metadata.startup-script` instead | ✅ Fixed in examples |
| `google_storage_bucket` — `lifecycle_rule.condition.age` now required | Must specify age for lifecycle rules | ✅ All rules include age |

### GCP-Specific Best Practices

1. **Use Service Accounts**: Never use user credentials for Terraform
2. **Enable Required APIs**: Always enable APIs before creating resources
3. **Use Labels**: Tag all resources for cost tracking and organization
4. **Regional Resources**: Prefer regional over zonal for high availability
5. **Use Workload Identity**: For GKE workloads instead of service account keys

**Reference**: [Google Provider v7 Changelog](https://github.com/hashicorp/terraform-provider-google/blob/main/CHANGELOG.md)

---

## 📚 Additional Resources

### GCP Documentation

- [GCP Free Tier](https://cloud.google.com/free)
- [GCP Documentation](https://cloud.google.com/docs)
- [Google Cloud SDK](https://cloud.google.com/sdk/docs)
- [GCP Architecture Framework](https://cloud.google.com/architecture/framework)

### Terraform GCP Provider

- [Google Provider Documentation](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [Google Provider Examples](https://github.com/hashicorp/terraform-provider-google/tree/main/examples)
- [Cloud Foundation Toolkit](https://cloud.google.com/foundation-toolkit)

### Community Resources

- [GCP Samples](https://github.com/GoogleCloudPlatform)
- [r/googlecloud](https://www.reddit.com/r/googlecloud/)
- [Google Cloud Community](https://www.googlecloudcommunity.com/)

---

## 🚧 Development Status

### Current Status: PLANNED

This course is currently in the planning phase. Content is being developed.

### Want to Help?

We're looking for contributors to help develop this course:

- **GCP Experts**: Help design course content
- **Terraform Practitioners**: Share real-world patterns
- **Technical Writers**: Help create documentation
- **Reviewers**: Test and provide feedback

See [CONTRIBUTING.md](../../CONTRIBUTING.md) for how to contribute.

### Expected Timeline

- **Q2 2026**: Course outline and structure ✅
- **Q3 2026**: Module content development
- **Q4 2026**: Review and testing
- **Q1 2027**: Course launch

---

## 🤝 Contributing

Help us build this course!

- Share GCP Terraform patterns
- Suggest topics to cover
- Review planned content
- Test examples when available
- Provide feedback

---

## 📜 License

This course is part of the hashi-training project and is licensed under the MIT License.

---

## 🙏 Acknowledgments

- HashiCorp for Terraform and Google provider
- Google Cloud for comprehensive documentation
- Cloud Foundation Toolkit community
- All contributors helping develop this course

---

**Status**: 🚧 Content in development

**Want updates?** Watch the repository for notifications when content is added.

**Questions?** Check the [Course Catalog](../../docs/course-catalog.md) or [FAQ](../../docs/faq.md)

---

*Last Updated: 2026-03-18*  
*Course Version: 1.0 (Planned)*  
*Terraform Version: 1.14+*  
*Google Provider Version: 7.24.0+*