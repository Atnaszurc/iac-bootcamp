# IBM Cloud Infrastructure with Terraform

## Course Overview

This comprehensive training series teaches Infrastructure as Code (IaC) on IBM Cloud using Terraform. Building on foundational Terraform knowledge, you'll learn to design, deploy, and manage production-grade cloud infrastructure following IBM Cloud best practices.

**Duration:** 8-12 hours  
**Level:** Intermediate  
**Prerequisites:** 
- Completion of IBM-201 (Setup & Authentication)
- Basic understanding of Terraform (variables, resources, state)
- Familiarity with cloud computing concepts
- IBM Cloud account with appropriate permissions

## Learning Path

This course follows a progressive learning model, building from fundamental concepts to advanced production patterns:

```
IBM-201: Setup & Auth → IBM-202: Compute & Networking → IBM-203: Security & Storage → IBM-204: Advanced Patterns
     (Foundation)              (Core Services)              (Security Layer)           (Production Ready)
```

## Course Modules

### [IBM-201: Setup & Authentication](./IBM-201-setup-auth/)
**Status:** ✅ Complete  
**Duration:** 1-2 hours

Learn to configure Terraform for IBM Cloud, understand authentication methods, and set up your development environment.

**Key Topics:**
- IBM Cloud provider configuration
- API key management and security
- Resource group organization
- Region and zone selection
- Provider version constraints

**Outcomes:**
- Configure Terraform for IBM Cloud
- Implement secure authentication
- Understand IBM Cloud organizational structure
- Set up reusable provider configurations

---

### [IBM-202: Compute & Networking](./IBM-202-compute-networking/)
**Status:** ✅ Complete  
**Duration:** 2-3 hours

Master IBM Cloud VPC networking and compute fundamentals, including Virtual Private Clouds, subnets, and Virtual Server Instances.

**Key Topics:**
- VPC architecture and design
- Subnet planning and CIDR blocks
- Public gateways vs. floating IPs
- SSH key management
- Virtual Server Instance provisioning
- Multi-zone deployments

**Outcomes:**
- Design and implement VPC networks
- Deploy Virtual Server Instances
- Configure network connectivity
- Implement multi-zone architectures
- Understand IBM Cloud networking concepts

**Labs:**
1. **Basic VPC Setup** - Create VPC with single subnet
2. **Multi-Zone Networking** - Deploy across availability zones
3. **Compute Deployment** - Launch and configure VSIs

---

### [IBM-203: Security & Storage](./IBM-203-security-storage/)
**Status:** ✅ Complete  
**Duration:** 2-3 hours

Implement defense-in-depth security using security groups, network ACLs, encryption, and secure storage solutions.

**Key Topics:**
- Security groups (stateful firewalls)
- Network ACLs (stateless firewalls)
- IBM Key Protect encryption
- Cloud Object Storage (COS)
- IAM authorization policies
- Encryption at rest and in transit

**Outcomes:**
- Implement layered security controls
- Configure security groups and ACLs
- Deploy Key Protect for encryption
- Set up Cloud Object Storage
- Manage service-to-service authorization
- Apply security best practices

**Labs:**
1. **Security Group Configuration** - Implement 3-tier security
2. **Network ACL Rules** - Add subnet-level controls
3. **Encryption Setup** - Deploy Key Protect and encrypted storage
4. **IAM Policies** - Configure service authorization

---

### [IBM-204: Advanced Patterns](./IBM-204-advanced-patterns/)
**Status:** ✅ Complete  
**Duration:** 3-4 hours

Build production-ready, multi-tier applications with load balancing, high availability, and integrated security.

**Key Topics:**
- Multi-tier architecture design
- Application Load Balancer configuration
- Health checks and monitoring
- High availability patterns
- Module composition
- Conditional resource deployment
- Production deployment strategies

**Outcomes:**
- Design multi-tier architectures
- Implement load balancing
- Configure health monitoring
- Deploy highly available systems
- Integrate all course concepts
- Apply production best practices

**Labs:**
1. **Load Balancer Setup** - Configure ALB with health checks
2. **Multi-Tier Deployment** - Deploy web, app, and database tiers
3. **High Availability** - Implement multi-zone redundancy
4. **Full Stack Integration** - Complete production architecture

---

## Course Architecture

The course follows a layered architecture approach:

```
┌─────────────────────────────────────────────────────────────┐
│                    IBM-204: Advanced Patterns                │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              Application Load Balancer                │   │
│  └──────────────────────────────────────────────────────┘   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │   Web Tier   │  │   App Tier   │  │ Database Tier│      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│              IBM-203: Security & Storage                     │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │Security Groups│  │ Network ACLs │  │ Key Protect  │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
│  ┌──────────────────────────────────────────────────────┐   │
│  │          Cloud Object Storage (Encrypted)             │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│            IBM-202: Compute & Networking                     │
│  ┌──────────────────────────────────────────────────────┐   │
│  │                    VPC Network                        │   │
│  │  ┌────────────┐  ┌────────────┐  ┌────────────┐     │   │
│  │  │Public Subnet│ │Private Sub │ │Database Sub │     │   │
│  │  └────────────┘  └────────────┘  └────────────┘     │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│           IBM-201: Setup & Authentication                    │
│  ┌──────────────────────────────────────────────────────┐   │
│  │    Provider Config │ API Keys │ Resource Groups      │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## Key Concepts Covered

### Infrastructure Design
- VPC architecture and network segmentation
- Multi-zone high availability
- Subnet design and CIDR planning
- Resource naming conventions
- Tagging strategies

### Security
- Defense-in-depth principles
- Security groups vs. Network ACLs
- Encryption at rest and in transit
- IAM authorization policies
- Least privilege access
- Security best practices

### Compute & Networking
- Virtual Server Instance management
- Load balancer configuration
- Health check implementation
- Public vs. private connectivity
- SSH key management
- Network routing

### Storage & Encryption
- Cloud Object Storage
- IBM Key Protect integration
- Encryption key management
- Bucket policies and access control
- Data protection strategies

### Terraform Best Practices
- Module composition
- Variable validation
- Conditional resource creation
- Output organization
- Testing with mock providers
- State management
- Documentation standards

## Hands-On Labs

Each module includes practical labs with:
- **Guided exercises** - Step-by-step implementation
- **Challenge scenarios** - Apply concepts independently
- **Quiz questions** - Validate understanding
- **Real-world examples** - Production-ready patterns

All labs use:
- ✅ Mock providers for cost-free testing
- ✅ Terraform test framework
- ✅ Comprehensive assertions
- ✅ Realistic scenarios

## Testing Strategy

Every module includes comprehensive tests:

```hcl
# Example test structure
run "plan_basic_deployment" {
  command = plan
  
  assert {
    condition     = output.vpc_id != null
    error_message = "Expected VPC to be created."
  }
}
```

**Test Coverage:**
- Basic resource creation
- Multi-zone deployments
- Security configurations
- Conditional deployments
- Full stack integration

## Prerequisites

### Required Knowledge
- Terraform basics (resources, variables, outputs)
- Basic networking concepts (CIDR, subnets, routing)
- Cloud computing fundamentals
- Command-line proficiency

### Required Tools
- Terraform 1.5.0 or later
- IBM Cloud CLI
- Text editor or IDE
- Git (for version control)

### IBM Cloud Access
- Active IBM Cloud account
- API key with appropriate permissions
- Access to:
  - VPC Infrastructure Services
  - Cloud Object Storage
  - Key Protect
  - IAM (for authorization policies)

## Getting Started

### 1. Complete Prerequisites
Ensure you have completed IBM-201 and have your IBM Cloud credentials configured.

### 2. Choose Your Path

**Sequential Learning (Recommended):**
```bash
cd IBM-202-compute-networking
# Complete all labs and exercises
cd ../IBM-203-security-storage
# Complete all labs and exercises
cd ../IBM-204-advanced-patterns
# Complete final integration
```

**Topic-Focused:**
Jump to specific modules based on your learning goals, but ensure you understand dependencies.

### 3. Run Tests
Each module includes tests you can run locally:

```bash
cd IBM-202-compute-networking/example
terraform init
terraform test
```

### 4. Deploy (Optional)
To deploy to actual IBM Cloud (incurs costs):

```bash
# Set your API key
export IC_API_KEY="your-api-key"

# Initialize and plan
terraform init
terraform plan

# Deploy
terraform apply
```

⚠️ **Cost Warning:** Deploying to IBM Cloud will incur charges. Always run `terraform destroy` when finished.

## Module Dependencies

```
IBM-201 (Required)
    ↓
IBM-202 ← IBM-203 (Can be done in parallel)
    ↓         ↓
    └─────────┴─→ IBM-204 (Requires both)
```

- **IBM-201** is required for all modules
- **IBM-202** and **IBM-203** can be completed in any order
- **IBM-204** requires completion of both IBM-202 and IBM-203

## Learning Outcomes

Upon completing this course, you will be able to:

✅ Design and implement IBM Cloud VPC networks  
✅ Deploy and manage Virtual Server Instances  
✅ Configure multi-zone high availability  
✅ Implement layered security controls  
✅ Deploy and manage encrypted storage  
✅ Configure application load balancers  
✅ Build production-ready multi-tier architectures  
✅ Apply Terraform best practices  
✅ Test infrastructure code effectively  
✅ Manage IBM Cloud resources at scale  

## Best Practices Emphasized

Throughout the course, you'll learn:

1. **Security First**
   - Always encrypt sensitive data
   - Implement least privilege access
   - Use security groups and ACLs together
   - Rotate credentials regularly

2. **High Availability**
   - Deploy across multiple zones
   - Use load balancers for distribution
   - Implement health checks
   - Plan for failure scenarios

3. **Infrastructure as Code**
   - Version control all configurations
   - Use modules for reusability
   - Validate inputs and outputs
   - Test before deploying
   - Document thoroughly

4. **Cost Optimization**
   - Right-size resources
   - Use appropriate instance profiles
   - Clean up unused resources
   - Monitor spending

5. **Operational Excellence**
   - Use consistent naming conventions
   - Tag resources appropriately
   - Implement monitoring
   - Plan for disaster recovery

## Additional Resources

### IBM Cloud Documentation
- [VPC Infrastructure](https://cloud.ibm.com/docs/vpc)
- [Virtual Server Instances](https://cloud.ibm.com/docs/vpc?topic=vpc-about-advanced-virtual-servers)
- [Security Groups](https://cloud.ibm.com/docs/vpc?topic=vpc-using-security-groups)
- [Key Protect](https://cloud.ibm.com/docs/key-protect)
- [Cloud Object Storage](https://cloud.ibm.com/docs/cloud-object-storage)

### Terraform Documentation
- [IBM Cloud Provider](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs)
- [Terraform Testing](https://developer.hashicorp.com/terraform/language/tests)
- [Module Development](https://developer.hashicorp.com/terraform/language/modules/develop)

### Community
- [IBM Cloud Community](https://community.ibm.com/community/user/cloud/home)
- [Terraform Community](https://discuss.hashicorp.com/c/terraform-core)

## Support

For questions or issues:
1. Review module README files
2. Check IBM Cloud documentation
3. Review Terraform provider documentation
4. Consult with your instructor or team

## Contributing

This training material is maintained as part of the HashiCorp IaC Bootcamp. For updates or corrections, please follow your organization's contribution guidelines.

## License

This training material is provided for educational purposes. Refer to your organization's policies for usage rights.

---

**Ready to begin?** Start with [IBM-201: Setup & Authentication](./IBM-201-setup-auth/) if you haven't completed it, or jump to [IBM-202: Compute & Networking](./IBM-202-compute-networking/) to begin building infrastructure!