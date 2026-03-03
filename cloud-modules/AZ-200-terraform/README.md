# AZ-200: Azure with Terraform

**Level**: 200 (Intermediate)  
**Duration**: 6 hours  
**Prerequisites**: TF-100 series (Terraform Fundamentals)  
**Platform**: Microsoft Azure  
**Status**: 🚧 **IN DEVELOPMENT** - Examples available, full content in progress

---

## 🎯 Course Overview

**AZ-200: Azure with Terraform** is an **optional cloud provider module** that teaches you how to apply the Terraform concepts you learned in the core training (TF-100, TF-200, TF-300) to Microsoft Azure.

This course assumes you've completed the **core Libvirt-based training** and are now ready to work with a real cloud provider. All the concepts you learned (variables, modules, validation, etc.) apply directly to Azure—you're just using different resources.

---

## 📚 What You'll Learn

### Core Competencies

After completing AZ-200, you will be able to:

- ✅ **Configure Azure Provider**: Set up authentication and provider configuration
- ✅ **Create Virtual Networks**: Build VNets, subnets, and network security
- ✅ **Deploy Virtual Machines**: Launch and manage Azure VMs
- ✅ **Implement Security**: Configure NSGs, RBAC, and Azure AD
- ✅ **Manage Storage**: Work with Storage Accounts and Managed Disks
- ✅ **Use Azure Services**: Integrate Azure SQL, Load Balancers, and more
- ✅ **Apply Core Concepts**: Use modules, validation, and patterns from core training

---

## 🗂️ Planned Course Modules

### AZ-201: Azure Setup & Authentication
**Duration**: 1 hour  
**Directory**: `AZ-201-setup-auth/` **[PLANNED]**

Learn to configure Azure access and the Terraform Azure provider.

**Topics** (Planned):
- Azure account setup
- Azure CLI installation and configuration
- Service Principal creation for Terraform
- Authentication methods (Service Principal, Managed Identity)
- Azure provider configuration
- Subscription and resource group concepts
- Best practices for Azure authentication
- Using Azure Cloud Shell

**Hands-On** (Planned):
- Set up Azure CLI
- Create Service Principal for Terraform
- Configure Azure credentials
- Write first Azure provider configuration
- Test Azure connectivity
- Configure multiple subscriptions
- Use Managed Identity

---

### AZ-202: Compute & Networking
**Duration**: 2 hours  
**Directory**: `AZ-202-compute-networking/` **[PLANNED]**

Build Azure networking infrastructure and deploy virtual machines.

**Topics** (Planned):
- Virtual Network (VNet) creation
- Subnets and address spaces
- Network Security Groups (NSGs)
- Azure Bastion for secure access
- Virtual Machine creation
- VM sizes and selection
- Custom images and Azure Marketplace
- SSH keys and authentication
- Cloud-init for VM initialization
- Availability Sets and Zones

**Hands-On** (Planned):
- Create VNet with multiple subnets
- Configure NSG rules
- Deploy Linux VMs
- Deploy Windows VMs
- Configure Azure Bastion
- Use cloud-init for configuration
- Build multi-tier network architecture
- Implement high availability

---

### AZ-203: Security & Storage
**Duration**: 2 hours  
**Directory**: `AZ-203-security-storage/` **[PLANNED]**

Implement Azure security best practices and manage storage resources.

**Topics** (Planned):
- Azure Active Directory integration
- Role-Based Access Control (RBAC)
- Managed Identities
- Azure Key Vault
- Storage Accounts (Blob, File, Queue, Table)
- Managed Disks
- Disk encryption
- Storage security and access control
- Azure Private Link
- Network security best practices

**Hands-On** (Planned):
- Configure RBAC roles
- Create Managed Identities
- Set up Azure Key Vault
- Create Storage Accounts
- Configure Blob storage
- Create and attach Managed Disks
- Implement disk encryption
- Use Private Endpoints
- Implement least privilege access

---

### AZ-204: Advanced Azure Patterns
**Duration**: 1 hour  
**Directory**: `AZ-204-advanced-patterns/` **[PLANNED]**

Implement advanced Azure patterns including load balancing, scaling, and multi-region deployments.

**Topics** (Planned):
- Azure Load Balancer
- Application Gateway
- Virtual Machine Scale Sets (VMSS)
- Azure SQL Database
- Azure Monitor and Log Analytics
- Multi-region deployments
- Traffic Manager
- Azure Front Door
- Production-ready patterns
- Cost optimization

**Hands-On** (Planned):
- Create Azure Load Balancer
- Configure Application Gateway
- Deploy VM Scale Sets
- Set up Azure SQL Database
- Implement multi-region architecture
- Configure Azure Monitor
- Build production-ready infrastructure
- Optimize costs

---

## 🎓 Learning Path

### Recommended Progression

```
Prerequisites: Complete TF-100, TF-200, TF-300
└── You already know Terraform!

Week 1: Azure Fundamentals
├── Day 1: AZ-201 (Setup & Authentication)
├── Day 2-3: AZ-202 (Compute & Networking)
└── Day 4-5: AZ-203 (Security & Storage)

Week 2: Advanced Azure
└── Day 1-2: AZ-204 (Advanced Patterns)
    └── Practice: Build production infrastructure
```

### Why After Core Training?

This course assumes you already understand:
- ✅ Terraform syntax and workflow
- ✅ Variables, loops, and functions
- ✅ Module design and composition
- ✅ State management
- ✅ Validation and testing

You're just learning **Azure-specific resources**, not Terraform itself.

---

## 💰 Cost Considerations

### Azure Free Tier

Azure offers a free tier that includes:
- **Virtual Machines**: 750 hours/month of B1S Windows or Linux VMs (12 months)
- **Storage**: 5 GB LRS blob storage, 5 GB LRS file storage
- **SQL Database**: 250 GB storage
- **Bandwidth**: 15 GB outbound data transfer
- **Always Free Services**: Many services free forever (with limits)

### Estimated Costs

If you stay within free tier limits:
- **Course Completion**: $0-5 (if careful)
- **Practice Projects**: $5-20/month

**Important**: Always clean up resources after practice to avoid charges!

### Cost Management Tips

1. **Use Free Tier**: Stay within free tier limits
2. **Clean Up**: Always destroy resources after practice
3. **Set Budgets**: Use Azure Cost Management + Billing
4. **Use B-series VMs**: Burstable, cost-effective instances
5. **Monitor Costs**: Check Azure Cost Analysis regularly
6. **Use Azure Advisor**: Get cost optimization recommendations

---

## 🚀 Getting Started

### Prerequisites

Before starting AZ-200, you must have:

1. **Completed Core Training**:
   - ✅ TF-100: Terraform Fundamentals
   - ✅ TF-200: Terraform Modules & Patterns (recommended)
   - ✅ TF-300: Testing & Validation (optional but helpful)

2. **Azure Account**:
   - Azure account (free tier eligible)
   - Credit card for account verification
   - Understanding of Azure billing

3. **Software**:
   - Terraform 1.14+
   - Azure CLI
   - Text editor (VS Code recommended)

### Setup Steps

```bash
# 1. Create Azure account
# Visit: https://azure.microsoft.com/free/

# 2. Install Azure CLI
# Ubuntu/Debian
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# macOS
brew install azure-cli

# Windows
# Download from: https://aka.ms/installazurecliwindows

# 3. Login to Azure
az login

# 4. Create Service Principal for Terraform
az ad sp create-for-rbac --name "terraform-sp" --role="Contributor" --scopes="/subscriptions/<subscription-id>"

# 5. Set environment variables
export ARM_CLIENT_ID="<appId>"
export ARM_CLIENT_SECRET="<password>"
export ARM_SUBSCRIPTION_ID="<subscription-id>"
export ARM_TENANT_ID="<tenant>"

# 6. Verify setup
az account show

# 7. Navigate to course (when available)
cd hashi-training/cloud-modules/AZ-200-terraform
```

---

## 📖 Course Materials

### What Will Be Included

Each module will contain:

- **README.md**: Detailed explanations and learning objectives
- **example/**: Working Terraform configurations for Azure
- **Exercises**: Hands-on labs with Azure resources
- **Cost Estimates**: Expected costs for each exercise
- **Cleanup Scripts**: Ensure resources are destroyed

### Planned Directory Structure

```
AZ-200-terraform/
├── README.md                          # This file
├── AZ-201-setup-auth/                 # [PLANNED]
│   ├── README.md
│   └── example/
├── AZ-202-compute-networking/         # [PLANNED]
│   ├── README.md
│   └── example/
├── AZ-203-security-storage/           # [PLANNED]
│   ├── README.md
│   └── example/
└── AZ-204-advanced-patterns/          # [PLANNED]
    ├── README.md
    └── example/
```

---

## 🎯 Learning Objectives

### By Module

#### After AZ-201, you will:
- Set up Azure account and Service Principal
- Configure Azure CLI and credentials
- Write Azure provider configurations
- Understand Azure authentication methods
- Use Managed Identities
- Work with multiple subscriptions

#### After AZ-202, you will:
- Create VNets with multiple subnets
- Configure Network Security Groups
- Deploy Linux and Windows VMs
- Configure Azure Bastion
- Implement high availability
- Build multi-tier network architectures

#### After AZ-203, you will:
- Configure RBAC and Managed Identities
- Use Azure Key Vault for secrets
- Create and manage Storage Accounts
- Work with Managed Disks
- Implement encryption
- Use Private Endpoints
- Follow security best practices

#### After AZ-204, you will:
- Configure load balancers
- Implement VM Scale Sets
- Deploy Azure SQL Database
- Set up Azure Monitor
- Build multi-region infrastructure
- Implement production-ready patterns
- Optimize Azure costs

---

## 🏆 Success Criteria

You've successfully completed AZ-200 when you can:

- [ ] Configure Azure provider and authentication
- [ ] Create VNet infrastructure from scratch
- [ ] Deploy VMs with proper security
- [ ] Manage RBAC and Managed Identities
- [ ] Configure Storage Accounts and Managed Disks
- [ ] Implement load balancing and scaling
- [ ] Build production-ready Azure infrastructure
- [ ] Apply core Terraform concepts to Azure
- [ ] Manage Azure costs effectively

---

## 🔄 What's Next?

### After AZ-200

Once you complete AZ-200, you can:

1. **AWS-200: AWS with Terraform**
   - Learn AWS-specific resources
   - Compare Azure and AWS approaches
   - Build multi-cloud skills

2. **MC-300: Multi-Cloud Architecture**
   - Abstract cloud differences
   - Build cloud-agnostic modules
   - Implement multi-cloud patterns

3. **Azure Certifications**:
   - Microsoft Certified: Azure Administrator Associate
   - Microsoft Certified: Azure Solutions Architect Expert
   - Microsoft Certified: DevOps Engineer Expert

4. **Real-World Projects**:
   - Build production Azure infrastructure
   - Implement CI/CD pipelines
   - Create self-service platforms
   - Contribute to Azure modules

---

## 💡 Why This Course is Optional

### Core Training is Cloud-Agnostic

The core training (TF-100, TF-200, TF-300) teaches you:
- Terraform syntax and concepts
- Module design patterns
- Validation and testing
- Best practices

These concepts apply to **any** cloud provider or infrastructure platform.

### AZ-200 is Just Application

This course teaches you:
- Azure-specific resource types
- Azure provider configuration
- Azure best practices

You're **applying** what you already know to Azure resources.

### Choose Your Path

- **Core Only**: Learn Terraform without cloud costs
- **Core + AWS**: Apply to most popular cloud
- **Core + Azure**: Apply to enterprise cloud
- **Core + Multi-Cloud**: Master multiple clouds

---

## 📚 Additional Resources

### Azure Documentation

- [Azure Free Account](https://azure.microsoft.com/free/)
- [Azure Documentation](https://docs.microsoft.com/azure/)
- [Azure CLI Documentation](https://docs.microsoft.com/cli/azure/)
- [Azure Architecture Center](https://docs.microsoft.com/azure/architecture/)

### Terraform Azure Provider

- [AzureRM Provider Documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure Provider Examples](https://github.com/hashicorp/terraform-provider-azurerm/tree/main/examples)
- [Azure Verified Modules](https://azure.github.io/Azure-Verified-Modules/)

### Community Resources

- [Azure Samples](https://github.com/Azure-Samples)
- [r/AZURE](https://www.reddit.com/r/AZURE/)
- [Microsoft Q&A](https://docs.microsoft.com/answers/products/azure)

---

## 🚧 Development Status

### Current Status: PLANNED

This course is currently in the planning phase. Content is being developed.

### Want to Help?

We're looking for contributors to help develop this course:

- **Azure Experts**: Help design course content
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

- Share Azure Terraform patterns
- Suggest topics to cover
- Review planned content
- Test examples when available
- Provide feedback

---

## 📜 License

This course is part of the hashi-training project and is licensed under the MIT License.

---

## 🙏 Acknowledgments

- HashiCorp for Terraform and Azure provider
- Microsoft for comprehensive Azure documentation
- Azure Verified Modules community
- All contributors helping develop this course

---

**Status**: 🚧 Content in development

**Want updates?** Watch the repository for notifications when content is added.

**Questions?** Check the [Course Catalog](../../docs/course-catalog.md) or [FAQ](../../docs/faq.md)

---

*Last Updated: 2026-02-26*  
*Course Version: 3.0 (Planned)*  
*Terraform Version: 1.14+*  
*AzureRM Provider Version: 4.0+*