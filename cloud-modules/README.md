# Cloud Provider Modules

**Type**: Optional Extension Modules  
**Prerequisites**: Core Training (TF-100, TF-200, TF-300)  
**Cost**: Requires cloud provider account (free tier available)

---

## 🎯 Overview

The cloud provider modules extend your core Terraform skills to real cloud environments. After completing the free core training with Libvirt, choose one or more cloud paths to apply your knowledge to production cloud infrastructure.

**Core training teaches the concepts. Cloud modules apply them.**

---

## 📚 Available Modules

### AWS-200: AWS with Terraform
**Duration**: 6 hours | **Directory**: `AWS-200-terraform/`

Apply your Terraform skills to Amazon Web Services — the world's most widely used cloud platform.

| Course | Topic | Duration |
|--------|-------|----------|
| AWS-201 | Setup & Authentication | 1h |
| AWS-202 | Compute & Networking (VPC, EC2, Security Groups) | 2h |
| AWS-203 | Security & Storage (S3, IAM, EBS) | 2h |
| AWS-204 | Advanced Patterns (Auto Scaling, Load Balancers) | 1h |

**Prerequisites**: AWS account (free tier sufficient for most labs)  
**[→ Start AWS-200](AWS-200-terraform/README.md)**

---

### AZ-200: Azure with Terraform
**Duration**: 6 hours | **Directory**: `AZ-200-terraform/`

Apply your Terraform skills to Microsoft Azure — the leading enterprise cloud platform.

| Course | Topic | Duration |
|--------|-------|----------|
| AZ-201 | Setup & Authentication | 1h |
| AZ-202 | Compute & Networking (VNet, VM, NSG) | 2h |
| AZ-203 | Security & Storage (Storage Account, Key Vault, Managed Disks) | 2h |
| AZ-204 | Advanced Patterns (Scale Sets, Load Balancers, Autoscale) | 1h |

**Prerequisites**: Azure account (free tier sufficient for most labs)  
**[→ Start AZ-200](AZ-200-terraform/README.md)**

---

### MC-300: Multi-Cloud Architecture
**Duration**: 4 hours | **Directory**: `MC-300-multi-cloud/`

Design and implement infrastructure that spans multiple cloud providers using advanced Terraform patterns.

| Course | Topic | Duration |
|--------|-------|----------|
| MC-301 | Multi-Cloud Strategy | 1h |
| MC-302 | Provider Abstraction Patterns | 1h |
| MC-303 | Cross-Cloud Networking | 1h |
| MC-304 | Advanced Multi-Cloud Patterns | 1h |

**Prerequisites**: AWS-200 AND AZ-200 (both required)  
**[→ Start MC-300](MC-300-multi-cloud/README.md)**

---

## 🗺️ Learning Paths

### Path A: Core Only (FREE)
```
TF-100 → TF-200 → TF-300 → PKR-100
Total: ~21 hours | Cost: $0
```
Best for: Learning IaC fundamentals, local development, budget-conscious learners.

### Path B: Core + AWS
```
TF-100 → TF-200 → TF-300 → AWS-200
Total: ~27 hours | Cost: AWS free tier
```
Best for: AWS-focused careers, most popular cloud platform.

### Path C: Core + Azure
```
TF-100 → TF-200 → TF-300 → AZ-200
Total: ~27 hours | Cost: Azure free tier
```
Best for: Enterprise environments, Microsoft shops.

### Path D: Multi-Cloud Expert
```
TF-100 → TF-200 → TF-300 → AWS-200 → AZ-200 → MC-300
Total: ~37 hours | Cost: Both free tiers
```
Best for: Cloud architects, multi-cloud environments.

---

## 💡 Which Cloud Should I Choose?

| Factor | AWS | Azure |
|--------|-----|-------|
| Market share | #1 (32%) | #2 (22%) |
| Job market | Largest | Strong enterprise |
| Free tier | 12 months + always free | 12 months + always free |
| Best for | Startups, web apps | Enterprise, Microsoft shops |
| Certifications | AWS SAA, SAP | AZ-104, AZ-305 |

**Not sure?** Start with AWS — it has the largest job market and most community resources.

---

## ⚠️ Important Notes

### Cost Management
- All examples use **free tier eligible** resources where possible
- Always run `terraform destroy` after labs to avoid charges
- Set up billing alerts before starting cloud labs
- Estimated lab costs: < $5/month if you destroy resources promptly

### Credentials Security
- **Never commit credentials to git** — use environment variables or credential files
- Use IAM roles/service principals with minimal permissions
- Rotate credentials regularly
- See each module's README for credential setup instructions

### Provider Compliance
- Cloud modules use cloud-specific providers (AWS, Azure)
- Core training (TF-100 through TF-300) uses only `dmacvicar/libvirt` and `hashicorp/local`
- This separation ensures core training is always free and offline-capable

---

## 🚀 Getting Started

1. **Complete core training first**: TF-100, TF-200, TF-300
2. **Choose your cloud path** (see table above)
3. **Set up your account**: Follow the setup guide in your chosen module's README
4. **Configure credentials**: Each module has authentication instructions
5. **Start with the 201 course**: Setup & Authentication

```bash
# Example: Start AWS path
cd cloud-modules/AWS-200-terraform
cat README.md

# Example: Start Azure path
cd cloud-modules/AZ-200-terraform
cat README.md
```

---

## 📊 Module Status

| Module | Status | Content |
|--------|--------|---------|
| AWS-200 | ✅ Ready | 4 courses, working examples |
| AZ-200 | ✅ Ready | 4 courses, working examples |
| MC-300 | 🚧 In Development | Structure ready, content planned |

---

*Part of the [hashi-training](../README.md) Zero-to-Hero IaC program*  
*Last Updated: 2026-02-28*