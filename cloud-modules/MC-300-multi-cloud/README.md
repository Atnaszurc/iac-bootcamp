# MC-300: Multi-Cloud Architecture

**Level**: 300 (Advanced)  
**Duration**: 4 hours  
**Prerequisites**: TF-200 series + AWS-200 and/or AZ-200  
**Platform**: Multiple Cloud Providers (AWS, Azure, GCP)  
**Status**: 🚧 **IN DEVELOPMENT** - Examples available, full content in progress

---

## 🎯 Course Overview

**MC-300: Multi-Cloud Architecture** is an **advanced optional module** that teaches you how to design and implement infrastructure that spans multiple cloud providers. Learn to abstract cloud differences, create portable modules, and build truly cloud-agnostic infrastructure.

This course assumes you've completed:
- ✅ **Core Training** (TF-100, TF-200, TF-300)
- ✅ **At least two cloud provider modules** (AWS-200 and/or AZ-200)

You'll learn to leverage the strengths of multiple clouds while managing complexity through abstraction and standardization.

---

## 📚 What You'll Learn

### Core Competencies

After completing MC-300, you will be able to:

- ✅ **Design Multi-Cloud Strategy**: Understand when and why to use multiple clouds
- ✅ **Abstract Cloud Differences**: Create provider-agnostic interfaces
- ✅ **Build Portable Modules**: Design modules that work across clouds
- ✅ **Implement Cross-Cloud Networking**: Connect infrastructure across providers
- ✅ **Manage Multi-Cloud State**: Handle state across multiple providers
- ✅ **Optimize Costs**: Leverage cloud-specific pricing advantages
- ✅ **Ensure Resilience**: Build fault-tolerant multi-cloud architectures

---

## 🗂️ Planned Course Modules

### MC-301: Multi-Cloud Strategy & Design
**Duration**: 1 hour  
**Directory**: `MC-301-strategy-design/` **[PLANNED]**

Learn when and why to use multi-cloud architectures, and how to design them effectively.

**Topics** (Planned):
- Multi-cloud vs hybrid cloud vs multi-region
- When to use multi-cloud (and when not to)
- Multi-cloud patterns and anti-patterns
- Vendor lock-in considerations
- Cost implications
- Complexity management
- Compliance and data sovereignty
- Disaster recovery strategies
- Cloud selection criteria

**Hands-On** (Planned):
- Analyze multi-cloud use cases
- Design multi-cloud architecture
- Evaluate cloud provider strengths
- Plan migration strategy
- Create decision matrix
- Document architecture decisions

**Key Skills**:
- Strategic thinking
- Architecture design
- Trade-off analysis
- Decision documentation

---

### MC-302: Provider Abstraction & Portable Modules
**Duration**: 1 hour  
**Directory**: `MC-302-abstraction-modules/` **[PLANNED]**

Create modules that abstract cloud provider differences and work across multiple clouds.

**Topics** (Planned):
- Provider abstraction patterns
- Cloud-agnostic interfaces
- Conditional provider selection
- Feature parity across clouds
- Handling cloud-specific features
- Module composition for multi-cloud
- Testing across providers
- Documentation strategies

**Hands-On** (Planned):
- Create cloud-agnostic compute module
- Build portable network module
- Implement provider selection logic
- Handle cloud-specific features gracefully
- Test modules across AWS and Azure
- Document provider differences

**Key Skills**:
- Abstraction design
- Module portability
- Provider selection
- Cross-cloud testing

---

### MC-303: Cross-Cloud Networking
**Duration**: 1 hour  
**Directory**: `MC-303-cross-cloud-networking/` **[PLANNED]**

Connect infrastructure across cloud providers using VPNs, direct connections, and overlay networks.

**Topics** (Planned):
- VPN connections between clouds
- AWS Direct Connect and Azure ExpressRoute
- Cloud interconnect services
- Overlay networks (WireGuard, Tailscale)
- DNS and service discovery
- Load balancing across clouds
- Latency considerations
- Security and encryption
- Cost optimization

**Hands-On** (Planned):
- Set up VPN between AWS and Azure
- Configure cross-cloud routing
- Implement service discovery
- Test cross-cloud connectivity
- Measure latency
- Secure cross-cloud traffic

**Key Skills**:
- Cross-cloud networking
- VPN configuration
- Service discovery
- Security implementation

---

### MC-304: Advanced Multi-Cloud Patterns
**Duration**: 1 hour  
**Directory**: `MC-304-advanced-patterns/` **[PLANNED]**

Implement advanced patterns including active-active deployments, cloud bursting, and disaster recovery.

**Topics** (Planned):
- Active-active multi-cloud deployments
- Cloud bursting patterns
- Disaster recovery across clouds
- Data replication strategies
- Global load balancing
- Multi-cloud CI/CD
- Cost optimization strategies
- Monitoring and observability
- Incident response

**Hands-On** (Planned):
- Deploy active-active application
- Implement cloud bursting
- Set up disaster recovery
- Configure global load balancing
- Build multi-cloud CI/CD pipeline
- Implement cross-cloud monitoring

**Key Skills**:
- Advanced deployment patterns
- Disaster recovery
- Global load balancing
- Multi-cloud operations

---

## 🎓 Learning Path

### Recommended Progression

```
Prerequisites: Complete TF-100, TF-200, TF-300, AWS-200, AZ-200
└── You know Terraform AND multiple clouds!

Week 1: Multi-Cloud Fundamentals
├── Day 1: MC-301 (Strategy & Design)
├── Day 2: MC-302 (Abstraction & Modules)
└── Day 3: MC-303 (Cross-Cloud Networking)

Week 2: Advanced Patterns
└── Day 1-2: MC-304 (Advanced Patterns)
    └── Practice: Build multi-cloud application
```

### Why This is Advanced

This course requires understanding of:
- ✅ Terraform fundamentals (TF-100)
- ✅ Module design (TF-200)
- ✅ Advanced patterns (TF-300)
- ✅ At least two cloud providers (AWS-200, AZ-200)

Multi-cloud adds significant complexity—you must master single-cloud first.

---

## 💰 Cost Considerations

### Multi-Cloud Costs

Multi-cloud infrastructure incurs costs from:
- **Multiple Cloud Accounts**: AWS + Azure + GCP
- **Data Transfer**: Cross-cloud traffic is expensive
- **Interconnect Services**: Direct Connect, ExpressRoute fees
- **Redundant Resources**: Running in multiple clouds
- **Management Overhead**: More complex = more time

### Estimated Costs

- **Course Completion**: $20-50 (multiple clouds)
- **Practice Projects**: $50-100/month
- **Production Multi-Cloud**: $$$$ (significant investment)

### Cost Optimization Tips

1. **Use Free Tiers**: Leverage free tiers in each cloud
2. **Minimize Data Transfer**: Keep data within clouds when possible
3. **Right-Size Resources**: Don't over-provision
4. **Clean Up Aggressively**: Destroy resources immediately after practice
5. **Monitor Costs**: Use cost management tools in each cloud
6. **Question Multi-Cloud**: Ensure the complexity is worth it

---

## 🚀 Getting Started

### Prerequisites

Before starting MC-300, you must have:

1. **Completed Core Training**:
   - ✅ TF-100: Terraform Fundamentals
   - ✅ TF-200: Terraform Modules & Patterns
   - ✅ TF-300: Testing & Validation (recommended)

2. **Completed Cloud Modules**:
   - ✅ AWS-200: AWS with Terraform (required)
   - ✅ AZ-200: Azure with Terraform (required)
   - ⚠️ GCP-200: GCP with Terraform (optional, when available)

3. **Cloud Accounts**:
   - Active AWS account
   - Active Azure account
   - (Optional) Active GCP account

4. **Software**:
   - Terraform 1.14+
   - AWS CLI
   - Azure CLI
   - (Optional) gcloud CLI

### Setup Steps

```bash
# 1. Ensure all CLIs are installed and configured
aws sts get-caller-identity
az account show
# gcloud auth list

# 2. Set up credentials for all providers
# AWS credentials in ~/.aws/credentials
# Azure credentials via az login
# GCP credentials via gcloud auth

# 3. Navigate to course (when available)
cd hashi-training/cloud-modules/MC-300-multi-cloud
```

---

## 📖 Course Materials

### What Will Be Included

Each module will contain:

- **README.md**: Detailed explanations and learning objectives
- **example/**: Working multi-cloud Terraform configurations
- **Exercises**: Hands-on labs spanning multiple clouds
- **Architecture Diagrams**: Visual representations of patterns
- **Cost Estimates**: Expected costs for each exercise
- **Cleanup Scripts**: Ensure resources are destroyed in all clouds

### Planned Directory Structure

```
MC-300-multi-cloud/
├── README.md                          # This file
├── MC-301-strategy-design/            # [PLANNED]
│   ├── README.md
│   └── examples/
├── MC-302-abstraction-modules/        # [PLANNED]
│   ├── README.md
│   └── examples/
├── MC-303-cross-cloud-networking/     # [PLANNED]
│   ├── README.md
│   └── examples/
└── MC-304-advanced-patterns/          # [PLANNED]
    ├── README.md
    └── examples/
```

---

## 🎯 Learning Objectives

### By Module

#### After MC-301, you will:
- Understand multi-cloud strategy and use cases
- Know when to use (and avoid) multi-cloud
- Design multi-cloud architectures
- Evaluate cloud provider strengths
- Plan multi-cloud migrations
- Document architecture decisions

#### After MC-302, you will:
- Create cloud-agnostic module interfaces
- Build portable modules
- Implement provider selection logic
- Handle cloud-specific features
- Test modules across providers
- Document provider differences

#### After MC-303, you will:
- Connect infrastructure across clouds
- Configure VPNs and direct connections
- Implement service discovery
- Secure cross-cloud traffic
- Optimize cross-cloud networking
- Measure and improve latency

#### After MC-304, you will:
- Deploy active-active applications
- Implement cloud bursting
- Set up disaster recovery
- Configure global load balancing
- Build multi-cloud CI/CD
- Monitor multi-cloud infrastructure

---

## 🏆 Success Criteria

You've successfully completed MC-300 when you can:

- [ ] Design effective multi-cloud architectures
- [ ] Create cloud-agnostic modules
- [ ] Connect infrastructure across clouds
- [ ] Implement active-active deployments
- [ ] Set up disaster recovery across clouds
- [ ] Manage multi-cloud state effectively
- [ ] Optimize multi-cloud costs
- [ ] Monitor multi-cloud infrastructure
- [ ] Explain trade-offs of multi-cloud

---

## 🔄 What's Next?

### After MC-300

Once you complete MC-300, you can:

1. **Real-World Multi-Cloud Projects**:
   - Build production multi-cloud infrastructure
   - Implement disaster recovery
   - Create global applications
   - Optimize for cost and performance

2. **Advanced Topics**:
   - Kubernetes across clouds
   - Service mesh for multi-cloud
   - Multi-cloud data pipelines
   - FinOps for multi-cloud

3. **Certifications**:
   - Multi-cloud architect certifications
   - Cloud-specific advanced certifications
   - Kubernetes certifications (CKA, CKAD)

4. **Contribute**:
   - Share multi-cloud patterns
   - Contribute to open-source modules
   - Write about multi-cloud experiences
   - Help others learn

---

## 💡 Why Multi-Cloud?

### Valid Reasons

✅ **Disaster Recovery**: True redundancy across providers  
✅ **Compliance**: Data sovereignty requirements  
✅ **Best-of-Breed**: Use best service from each cloud  
✅ **Vendor Negotiation**: Avoid lock-in for better pricing  
✅ **Geographic Coverage**: Better global presence  
✅ **Acquisition**: Inherited infrastructure from M&A

### Invalid Reasons

❌ **"Just in case"**: Complexity without clear benefit  
❌ **Resume-driven**: Learning at company expense  
❌ **Fear of lock-in**: Without actual lock-in risk  
❌ **Trend-following**: Because everyone else does it  
❌ **Avoiding decisions**: Keeping options open indefinitely

### The Reality

Multi-cloud is **complex and expensive**. Only pursue it if you have:
- Clear business requirements
- Resources to manage complexity
- Team expertise in multiple clouds
- Budget for increased costs

---

## ⚠️ AWS Provider v6 Compatibility

All MC-300 examples use `hashicorp/aws ~> 6.0`. Key breaking changes from v5 → v6 that affect these examples:

| Change | Status in Examples |
|--------|--------------------|
| `aws_security_group` inline `ingress`/`egress` deprecated → use `aws_vpc_security_group_ingress_rule` / `aws_vpc_security_group_egress_rule` | ✅ Documented in comments |
| `aws_eip` — `vpc` attribute removed → use `domain = "vpc"` | ✅ Fixed |
| `aws_instance.user_data` — now stored in cleartext | ✅ Documented in comments |
| `data "aws_ami"` — must have `owners` when `most_recent = true` | ✅ All AMI lookups use `owners` |

**Reference**: [AWS Provider v6 Upgrade Guide](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/guides/version-6-upgrade)

---

## 📚 Additional Resources

### Multi-Cloud Documentation

- [Terraform Multi-Cloud](https://www.terraform.io/use-cases/multi-cloud-deployment)
- [AWS Multi-Cloud](https://aws.amazon.com/hybrid/)
- [Azure Arc](https://azure.microsoft.com/services/azure-arc/)
- [Google Anthos](https://cloud.google.com/anthos)

### Architecture Patterns

- [Multi-Cloud Architecture Patterns](https://www.hashicorp.com/resources/multi-cloud-architecture-patterns)
- [Cloud Adoption Framework](https://docs.microsoft.com/azure/cloud-adoption-framework/)
- [AWS Well-Architected](https://aws.amazon.com/architecture/well-architected/)

### Community Resources

- [CNCF Multi-Cloud](https://www.cncf.io/)
- [Multi-Cloud Networking](https://www.aviatrix.com/)
- [Terraform Multi-Cloud Modules](https://registry.terraform.io/)

---

## 🚧 Development Status

### Current Status: PLANNED

This course is currently in the planning phase. Content is being developed.

### Prerequisites for Development

Before this course can be developed, we need:
- ✅ Core training complete (TF-100, TF-200, TF-300)
- 🚧 AWS-200 complete
- 🚧 AZ-200 complete
- ⏳ GCP-200 (optional)

### Want to Help?

We're looking for contributors with multi-cloud experience:

- **Multi-Cloud Architects**: Help design course content
- **Terraform Experts**: Share multi-cloud patterns
- **Network Engineers**: Help with cross-cloud networking
- **Technical Writers**: Help create documentation
- **Reviewers**: Test and provide feedback

See [CONTRIBUTING.md](../../CONTRIBUTING.md) for how to contribute.

### Expected Timeline

- **Q3 2026**: Course outline and structure (after AWS-200, AZ-200)
- **Q4 2026**: Module content development
- **Q1 2027**: Review and testing
- **Q2 2027**: Course launch

---

## 🤝 Contributing

Help us build this course!

- Share multi-cloud Terraform patterns
- Suggest topics to cover
- Review planned content
- Test examples when available
- Provide feedback on multi-cloud challenges

---

## 📜 License

This course is part of the hashi-training project and is licensed under the MIT License.

---

## 🙏 Acknowledgments

- HashiCorp for Terraform's multi-cloud capabilities
- Cloud providers for interconnect services
- Multi-cloud practitioners sharing their experiences
- All contributors helping develop this course

---

**Status**: 🚧 Content in development (requires AWS-200 and AZ-200 first)

**Want updates?** Watch the repository for notifications when content is added.

**Questions?** Check the [Course Catalog](../../docs/course-catalog.md) or [FAQ](../../docs/faq.md)

---

*Last Updated: 2026-02-26*  
*Course Version: 3.0 (Planned)*  
*Terraform Version: 1.14+*  
*Multi-Provider Support: AWS, Azure, GCP*
---

## 🔄 AWS Provider v6 Changes

> **All MC-300 examples use `hashicorp/aws ~> 6.0`** (upgraded from 5.x). The following breaking changes from the [AWS Provider v6 Upgrade Guide](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/guides/version-6-upgrade) apply to the AWS resources used in this module:

### Changes applied in MC-300 examples

| Change | Affected Resource | Status |
|--------|------------------|--------|
| `data.aws_region.*.name` → `.region` | MC-301 | ✅ Fixed |
| `aws_ami` requires `owners` with `most_recent = true` | MC-302, MC-304 | ✅ Fixed |
| `aws_eip.vpc = true` → `domain = "vpc"` | MC-304 | ✅ Fixed |
| `aws_instance.user_data` stored in cleartext | MC-304 | ✅ Documented |
| `aws_security_group` inline rules deprecated | MC-302, MC-303, MC-304 | ✅ Documented |

### `aws_eip` — `vpc` attribute removed, use `domain`

```hcl
# ❌ v5 and earlier
resource "aws_eip" "primary" {
  instance = aws_instance.primary.id
  vpc      = true  # removed in v6
}

# ✅ v6+
resource "aws_eip" "primary" {
  instance = aws_instance.primary.id
  domain   = "vpc"  # use domain instead
}
```

### `aws_security_group` — inline rules deprecated

The modern v6 approach uses separate `aws_vpc_security_group_ingress_rule` and `aws_vpc_security_group_egress_rule` resources. MC-300 examples retain inline rules for training clarity with deprecation comments.

### `aws_s3_bucket` — `bucket_region` attribute

In v6, use `bucket_region` (not `region`) to get the bucket's AWS region. The `region` attribute is now used for Enhanced Region Support.

**Reference**: [AWS Provider v6 Upgrade Guide](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/guides/version-6-upgrade)