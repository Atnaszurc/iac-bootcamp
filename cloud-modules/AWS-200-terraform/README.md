# AWS-200: AWS with Terraform

**Level**: 200 (Intermediate)  
**Duration**: 6 hours  
**Prerequisites**: TF-100 series (Terraform Fundamentals)  
**Platform**: AWS (Amazon Web Services)  
**Status**: 🚧 **IN DEVELOPMENT** - Examples available, full content in progress

---

## 🎯 Course Overview

**AWS-200: AWS with Terraform** is an **optional cloud provider module** that teaches you how to apply the Terraform concepts you learned in the core training (TF-100, TF-200, TF-300) to Amazon Web Services.

This course assumes you've completed the **core Libvirt-based training** and are now ready to work with a real cloud provider. All the concepts you learned (variables, modules, validation, etc.) apply directly to AWS—you're just using different resources.

---

## 📚 What You'll Learn

### Core Competencies

After completing AWS-200, you will be able to:

- ✅ **Configure AWS Provider**: Set up authentication and provider configuration
- ✅ **Create VPC Infrastructure**: Build networks, subnets, and routing
- ✅ **Deploy EC2 Instances**: Launch and manage virtual machines
- ✅ **Implement Security**: Configure security groups, IAM roles, and policies
- ✅ **Manage Storage**: Work with S3 buckets and EBS volumes
- ✅ **Use AWS Services**: Integrate RDS, ELB, Auto Scaling, and more
- ✅ **Apply Core Concepts**: Use modules, validation, and patterns from core training

---

## 🗂️ Planned Course Modules

### AWS-201: AWS Setup & Authentication
**Duration**: 1 hour  
**Directory**: `AWS-201-setup-auth/` **[PLANNED]**

Learn to configure AWS access and the Terraform AWS provider.

**Topics** (Planned):
- AWS account setup
- AWS CLI installation and configuration
- IAM user creation for Terraform
- Access keys and credentials management
- AWS provider configuration
- Region and availability zone selection
- Best practices for AWS authentication
- Using AWS profiles

**Hands-On** (Planned):
- Set up AWS CLI
- Create IAM user for Terraform
- Configure AWS credentials
- Write first AWS provider configuration
- Test AWS connectivity
- Configure multiple AWS profiles

---

### AWS-202: Compute & Networking
**Duration**: 2 hours  
**Directory**: `AWS-202-compute-networking/` **[PLANNED]**

Build AWS networking infrastructure and deploy EC2 instances.

**Topics** (Planned):
- VPC (Virtual Private Cloud) creation
- Subnets (public and private)
- Internet Gateway and NAT Gateway
- Route tables and routing
- EC2 instance types and selection
- AMI selection and management
- Security groups
- Key pairs for SSH access
- User data for instance initialization

**Hands-On** (Planned):
- Create VPC with public/private subnets
- Configure routing and gateways
- Launch EC2 instances
- Configure security groups
- SSH into instances
- Use user data for configuration
- Build multi-tier network architecture

---

### AWS-203: Security & Storage
**Duration**: 2 hours  
**Directory**: `AWS-203-security-storage/` **[PLANNED]**

Implement AWS security best practices and manage storage resources.

**Topics** (Planned):
- IAM roles and policies
- IAM instance profiles
- Security group best practices
- Network ACLs
- S3 bucket creation and configuration
- S3 bucket policies
- EBS volumes and snapshots
- Encryption at rest and in transit
- AWS Secrets Manager
- Parameter Store

**Hands-On** (Planned):
- Create IAM roles for EC2
- Attach IAM policies
- Configure S3 buckets
- Implement bucket policies
- Create and attach EBS volumes
- Encrypt storage resources
- Use Secrets Manager
- Implement least privilege access

---

### AWS-204: Advanced AWS Patterns
**Duration**: 1 hour  
**Directory**: `AWS-204-advanced-patterns/` **[PLANNED]**

Implement advanced AWS patterns including auto-scaling, load balancing, and multi-region deployments.

**Topics** (Planned):
- Application Load Balancer (ALB)
- Network Load Balancer (NLB)
- Auto Scaling Groups
- Launch Templates
- Target Groups
- Multi-region deployments
- RDS database deployment
- CloudWatch monitoring
- SNS notifications
- Production-ready patterns

**Hands-On** (Planned):
- Create Application Load Balancer
- Configure Auto Scaling Group
- Deploy multi-tier application
- Set up RDS database
- Implement multi-region architecture
- Configure CloudWatch alarms
- Build production-ready infrastructure

---

## 🎓 Learning Path

### Recommended Progression

```
Prerequisites: Complete TF-100, TF-200, TF-300
└── You already know Terraform!

Week 1: AWS Fundamentals
├── Day 1: AWS-201 (Setup & Authentication)
├── Day 2-3: AWS-202 (Compute & Networking)
└── Day 4-5: AWS-203 (Security & Storage)

Week 2: Advanced AWS
└── Day 1-2: AWS-204 (Advanced Patterns)
    └── Practice: Build production infrastructure
```

### Why After Core Training?

This course assumes you already understand:
- ✅ Terraform syntax and workflow
- ✅ Variables, loops, and functions
- ✅ Module design and composition
- ✅ State management
- ✅ Validation and testing

You're just learning **AWS-specific resources**, not Terraform itself.

---

## 💰 Cost Considerations

### AWS Free Tier

AWS offers a free tier that includes:
- **EC2**: 750 hours/month of t2.micro or t3.micro instances (12 months)
- **S3**: 5 GB storage, 20,000 GET requests, 2,000 PUT requests
- **RDS**: 750 hours/month of db.t2.micro, db.t3.micro, or db.t4g.micro (12 months)
- **EBS**: 30 GB of storage
- **Data Transfer**: 15 GB outbound per month

### Estimated Costs

If you stay within free tier limits:
- **Course Completion**: $0-5 (if careful)
- **Practice Projects**: $5-20/month

**Important**: Always clean up resources after practice to avoid charges!

### Cost Management Tips

1. **Use Free Tier**: Stay within free tier limits
2. **Clean Up**: Always destroy resources after practice
3. **Set Budgets**: Use AWS Budgets to set spending alerts
4. **Use t2.micro/t3.micro**: Smallest instance types
5. **Monitor Costs**: Check AWS Cost Explorer regularly

---

## 🚀 Getting Started

### Prerequisites

Before starting AWS-200, you must have:

1. **Completed Core Training**:
   - ✅ TF-100: Terraform Fundamentals
   - ✅ TF-200: Terraform Modules & Patterns (recommended)
   - ✅ TF-300: Testing & Validation (optional but helpful)

2. **AWS Account**:
   - AWS account (free tier eligible)
   - Credit card for account verification
   - Understanding of AWS billing

3. **Software**:
   - Terraform 1.14+
   - AWS CLI
   - Text editor (VS Code recommended)

### Setup Steps

```bash
# 1. Create AWS account
# Visit: https://aws.amazon.com/free/

# 2. Install AWS CLI
# Ubuntu/Debian
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# macOS
brew install awscli

# 3. Configure AWS CLI
aws configure
# Enter: Access Key ID, Secret Access Key, Region, Output format

# 4. Verify setup
aws sts get-caller-identity

# 5. Navigate to course (when available)
cd hashi-training/cloud-modules/AWS-200-terraform
```

---

## 📖 Course Materials

### What Will Be Included

Each module will contain:

- **README.md**: Detailed explanations and learning objectives
- **example/**: Working Terraform configurations for AWS
- **Exercises**: Hands-on labs with AWS resources
- **Cost Estimates**: Expected costs for each exercise
- **Cleanup Scripts**: Ensure resources are destroyed

### Planned Directory Structure

```
AWS-200-terraform/
├── README.md                          # This file
├── AWS-201-setup-auth/                # [PLANNED]
│   ├── README.md
│   └── example/
├── AWS-202-compute-networking/        # [PLANNED]
│   ├── README.md
│   └── example/
├── AWS-203-security-storage/          # [PLANNED]
│   ├── README.md
│   └── example/
└── AWS-204-advanced-patterns/         # [PLANNED]
    ├── README.md
    └── example/
```

---

## 🎯 Learning Objectives

### By Module

#### After AWS-201, you will:
- Set up AWS account and IAM users
- Configure AWS CLI and credentials
- Write AWS provider configurations
- Understand AWS authentication methods
- Use AWS profiles for multiple accounts

#### After AWS-202, you will:
- Create VPCs with public/private subnets
- Configure routing and gateways
- Launch and manage EC2 instances
- Configure security groups
- Build multi-tier network architectures

#### After AWS-203, you will:
- Create and manage IAM roles
- Configure S3 buckets and policies
- Manage EBS volumes
- Implement encryption
- Use AWS Secrets Manager
- Follow security best practices

#### After AWS-204, you will:
- Configure load balancers
- Implement auto-scaling
- Deploy multi-region infrastructure
- Set up RDS databases
- Build production-ready AWS infrastructure

---

## 🏆 Success Criteria

You've successfully completed AWS-200 when you can:

- [ ] Configure AWS provider and authentication
- [ ] Create VPC infrastructure from scratch
- [ ] Deploy EC2 instances with proper security
- [ ] Manage IAM roles and policies
- [ ] Configure S3 buckets and storage
- [ ] Implement load balancing and auto-scaling
- [ ] Build production-ready AWS infrastructure
- [ ] Apply core Terraform concepts to AWS
- [ ] Manage AWS costs effectively

---

## 🔄 What's Next?

### After AWS-200

Once you complete AWS-200, you can:

1. **AZ-200: Azure with Terraform**
   - Learn Azure-specific resources
   - Compare AWS and Azure approaches
   - Build multi-cloud skills

2. **MC-300: Multi-Cloud Architecture**
   - Abstract cloud differences
   - Build cloud-agnostic modules
   - Implement multi-cloud patterns

3. **AWS Certifications**:
   - AWS Certified Solutions Architect - Associate
   - AWS Certified Developer - Associate
   - AWS Certified SysOps Administrator - Associate

4. **Real-World Projects**:
   - Build production AWS infrastructure
   - Implement CI/CD pipelines
   - Create self-service platforms
   - Contribute to AWS modules

---

## 💡 Why This Course is Optional

### Core Training is Cloud-Agnostic

The core training (TF-100, TF-200, TF-300) teaches you:
- Terraform syntax and concepts
- Module design patterns
- Validation and testing
- Best practices

These concepts apply to **any** cloud provider or infrastructure platform.

### AWS-200 is Just Application

This course teaches you:
- AWS-specific resource types
- AWS provider configuration
- AWS best practices

You're **applying** what you already know to AWS resources.

### Choose Your Path

- **Core Only**: Learn Terraform without cloud costs
- **Core + AWS**: Apply to most popular cloud
- **Core + Azure**: Apply to enterprise cloud
- **Core + Multi-Cloud**: Master multiple clouds

---

## ⚠️ AWS Provider v6 Compatibility

All examples in this module use `hashicorp/aws ~> 6.0`. The following breaking changes from v5 → v6 are relevant to this training:

| Change | Impact | Status in Examples |
|--------|--------|--------------------|
| `data "aws_region"` — `name` deprecated → use `region` | `data.aws_region.current.name` → `.region` | ✅ Fixed (`main.tf` uses `.region`) |
| `aws_instance.user_data` — now stored in cleartext (no longer hashed) | Do NOT include passwords in `user_data` | ✅ Documented in comments |
| `aws_security_group` inline `ingress`/`egress` — deprecated | Use `aws_vpc_security_group_ingress_rule` / `aws_vpc_security_group_egress_rule` for new code | ✅ Documented in comments |
| `aws_eip` — `vpc` attribute removed → use `domain` | `vpc = true` → `domain = "vpc"` | ✅ Fixed |
| `aws_launch_template` — `elastic_gpu_specifications` removed | Amazon Elastic Graphics reached end of life | ✅ Not used in examples |
| `aws_launch_template` — `elastic_inference_accelerator` removed | Amazon Elastic Inference reached end of life | ✅ Not used in examples |
| `data "aws_ami"` — must have `owners` or `owner-id` filter when `most_recent = true` | Prevents ambiguous AMI lookups | ✅ All AMI lookups use `owners` |
| `aws_s3_bucket` — `region` now used for Enhanced Region Support | Use `bucket_region` for the bucket's region attribute | ✅ Not referenced in examples |
| OpsWorks, SimpleDB, Worklink resources — removed | These services reached end of life | ✅ Not used in examples |

### Enhanced Region Support (v6 New Feature)

AWS provider v6 adds a `region` argument to most resources, making it easier to manage infrastructure across regions without multiple provider configurations:

```hcl
# v6: deploy a resource in a different region without a separate provider alias
resource "aws_s3_bucket" "logs" {
  bucket = "my-logs-bucket"
  region = "eu-west-1"  # New in v6 — no need for provider alias
}
```

**Reference**: [AWS Provider v6 Upgrade Guide](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/guides/version-6-upgrade)

---

## 📚 Additional Resources

### AWS Documentation

- [AWS Free Tier](https://aws.amazon.com/free/)
- [AWS Documentation](https://docs.aws.amazon.com/)
- [AWS CLI Documentation](https://docs.aws.amazon.com/cli/)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)

### Terraform AWS Provider

- [AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS Provider Examples](https://github.com/hashicorp/terraform-provider-aws/tree/main/examples)
- [Terraform AWS Modules](https://github.com/terraform-aws-modules)

### Community Resources

- [AWS Samples](https://github.com/aws-samples)
- [r/aws](https://www.reddit.com/r/aws/)
- [AWS re:Post](https://repost.aws/)

---

## 🚧 Development Status

### Current Status: PLANNED

This course is currently in the planning phase. Content is being developed.

### Want to Help?

We're looking for contributors to help develop this course:

- **AWS Experts**: Help design course content
- **Terraform Practitioners**: Share real-world patterns
- **Technical Writers**: Help create documentation
- **Reviewers**: Test and provide feedback

See [CONTRIBUTING.md](../../CONTRIBUTING.md) for how to contribute.

### Expected Timeline

- **Q2 2026**: Course outline and structure
- **Q3 2026**: Module content development
- **Q4 2026**: Review and testing
- **Q1 2027**: Course launch

---

## 🤝 Contributing

Help us build this course!

- Share AWS Terraform patterns
- Suggest topics to cover
- Review planned content
- Test examples when available
- Provide feedback

---

## 📜 License

This course is part of the hashi-training project and is licensed under the MIT License.

---

## 🙏 Acknowledgments

- HashiCorp for Terraform and AWS provider
- AWS for comprehensive documentation
- Terraform AWS Modules community
- All contributors helping develop this course

---

**Status**: 🚧 Content in development

**Want updates?** Watch the repository for notifications when content is added.

**Questions?** Check the [Course Catalog](../../docs/course-catalog.md) or [FAQ](../../docs/faq.md)

---

*Last Updated: 2026-02-26*  
*Course Version: 3.0 (Planned)*  
*Terraform Version: 1.14+*  
*AWS Provider Version: 6.0+*