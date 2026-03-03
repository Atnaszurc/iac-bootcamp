# TF-200: Terraform Modules & Patterns

**Level**: 200 (Intermediate)  
**Duration**: 6 hours  
**Prerequisites**: TF-100 series (Terraform Fundamentals)  
**Platform**: Libvirt (local VMs)

---

## 🎯 Course Overview

Welcome to **TF-200: Terraform Modules & Patterns**! This intermediate course transforms you from writing basic Terraform configurations to creating professional, reusable infrastructure components. You'll learn how to design modules, implement advanced patterns, and build infrastructure that scales across teams and environments.

This course focuses on **code organization**, **reusability**, and **enterprise patterns** that are essential for production Terraform usage.

---

## 📚 What You'll Learn

### Core Competencies

After completing TF-200, you will be able to:

- ✅ **Design Professional Modules**: Create well-structured, reusable infrastructure components
- ✅ **Implement Module Composition**: Build complex infrastructure from simple building blocks
- ✅ **Use Advanced Patterns**: Implement canary deployments, blue-green patterns, and more
- ✅ **Drive Configuration with YAML**: Create flexible, data-driven infrastructure
- ✅ **Import Existing Infrastructure**: Bring existing resources under Terraform management
- ✅ **Migrate and Refactor**: Safely restructure Terraform code
- ✅ **Collaborate with Teams**: Share and version modules effectively

---

## 🗂️ Course Modules

### TF-201: Module Design & Composition
**Duration**: 1.5 hours  
**Directory**: `TF-201-module-design/`

Learn professional module design patterns and how to compose modules together to build complex infrastructure.

**Topics**:
- Module design principles and best practices
- Input variable design (required vs optional)
- Output design for composition
- Optional attributes (Terraform 1.3+)
- Dynamic blocks for flexibility
- Module composition patterns
- Module documentation standards
- Versioning strategies

**Hands-On**:
- Design a network module from scratch
- Create a VM module that uses the network module
- Implement optional attributes for flexibility
- Use dynamic blocks for complex configurations
- Compose modules together
- Document modules with examples

**Key Skills**:
- Professional module structure
- Module composition techniques
- Optional attribute patterns
- Documentation best practices

---

### TF-202: Advanced Module Patterns
**Duration**: 1.5 hours  
**Directory**: `TF-202-advanced-patterns/`

Implement enterprise-grade deployment patterns including private registries and advanced deployment strategies.

**Topics**:
- **1-private-registry/**: Publishing modules to HCP Terraform/Terraform Cloud
  - Module registry setup
  - Publishing and versioning
  - Module discovery
  - Access control
  - Team collaboration

- **2-canary-deployments/**: Implementing canary deployment patterns
  - Canary deployment concepts
  - Traffic splitting strategies
  - Rollback procedures
  - Monitoring and validation
  - Azure-specific examples

**Hands-On**:
- Set up HCP Terraform account (optional)
- Publish a module to private registry
- Implement canary deployment pattern
- Test deployment strategies
- Practice rollback procedures

**Key Skills**:
- Module publishing workflows
- Canary deployment implementation
- Blue-green deployment patterns
- Enterprise collaboration

---

### TF-203: YAML-Driven Configuration
**Duration**: 1.5 hours  
**Directory**: `TF-203-yaml-config/`

Create flexible, data-driven infrastructure using YAML configuration files. Learn to separate infrastructure logic from configuration data.

**Topics**:
- YAML parsing with `yamldecode()`
- YAML-driven resource creation
- Using `locals` with YAML data
- `for_each` with YAML configurations
- Complex YAML structures
- YAML validation strategies
- Configuration file organization
- Multi-environment patterns

**Hands-On**:
- Create YAML-driven network configurations
- Build VM infrastructure from YAML files
- Implement multi-environment setup
- Validate YAML configurations
- Create reusable YAML patterns

**Key Skills**:
- YAML-driven infrastructure
- Data/logic separation
- Configuration management
- Multi-environment patterns

---

### TF-204: Import & Migration Strategies
**Duration**: 1.5 hours  
**Directory**: `TF-204-import-migration/`

Learn to import existing infrastructure into Terraform and safely migrate/refactor Terraform code.

**Topics**:
- Import blocks (Terraform 1.5+)
- `terraform import` CLI command
- Importing Libvirt resources
- State migration strategies
- `moved` blocks for refactoring
- Resource renaming
- Module refactoring
- Safe migration practices

**Hands-On**:
- Import existing Libvirt resources
- Use import blocks for declarative imports
- Migrate resources between modules
- Refactor code with `moved` blocks
- Practice safe state manipulation

**Key Skills**:
- Infrastructure import techniques
- State migration strategies
- Code refactoring patterns
- Safe Terraform operations

---

## 🎓 Learning Path

### Recommended Progression

```
Week 1: Module Fundamentals
├── Day 1-2: TF-201 (Module Design & Composition)
└── Day 3-4: TF-202 (Advanced Module Patterns)

Week 2: Configuration & Migration
├── Day 1-2: TF-203 (YAML-Driven Configuration)
└── Day 3-4: TF-204 (Import & Migration Strategies)
```

### Time Commitment

- **Self-Paced**: 6 hours of core content
- **With Practice**: 8-10 hours (recommended)
- **Full Mastery**: 12-15 hours (includes experimentation)

---

## 🚀 Getting Started

### Prerequisites

Before starting TF-200, you must have:

1. **Completed TF-100**: All four modules (TF-101 through TF-104)
2. **Comfortable with**:
   - Writing Terraform configurations
   - Using variables and loops
   - Managing infrastructure resources
   - Terraform state concepts
   - Basic CLI operations

3. **System Requirements**:
   - Same as TF-100 (Libvirt + Terraform installed)
   - 8 GB RAM minimum (16 GB recommended)
   - 50 GB free disk space

### Quick Start

```bash
# 1. Navigate to the course directory
cd hashi-training/TF-200-modules

# 2. Start with TF-201
cd TF-201-module-design
cat README.md

# 3. Follow the exercises in order
# Each module builds on previous knowledge
```

---

## 📖 Course Materials

### What's Included

Each module contains:

- **README.md**: Detailed explanations and learning objectives
- **example/**: Working Terraform configurations
- **Exercises**: Hands-on labs to practice concepts
- **Solutions**: Reference implementations
- **Best Practices**: Industry-standard patterns

### Directory Structure

```
TF-200-modules/
├── README.md                          # This file
├── TF-201-module-design/
│   ├── README.md                      # Module guide
│   └── example/                       # Module examples
├── TF-202-advanced-patterns/
│   ├── README.md                      # Module overview
│   ├── 1-private-registry/            # Registry publishing
│   └── 2-canary-deployments/          # Canary patterns
├── TF-203-yaml-config/
│   ├── README.md                      # Module guide
│   └── example/                       # YAML examples
└── TF-204-import-migration/
    ├── README.md                      # Module guide
    └── example/                       # Import examples
```

---

## 🎯 Learning Objectives

### By Module

#### After TF-201, you will:
- Design modules following industry best practices
- Implement module composition (modules calling modules)
- Use optional attributes effectively (Terraform 1.3+)
- Create dynamic blocks for flexibility
- Version modules properly
- Document modules professionally

#### After TF-202, you will:
- Publish modules to private registries
- Implement canary deployment patterns
- Implement blue-green deployment patterns
- Version modules semantically
- Collaborate with teams using modules
- Manage module dependencies

#### After TF-203, you will:
- Parse and use YAML configuration files
- Create YAML-driven infrastructure
- Separate configuration from logic
- Implement multi-environment patterns
- Validate YAML configurations
- Organize configuration files effectively

#### After TF-204, you will:
- Import existing infrastructure into Terraform
- Use import blocks (Terraform 1.5+)
- Migrate resources between modules
- Refactor code safely with `moved` blocks
- Rename resources without recreation
- Perform safe state operations

---

## 🏆 Success Criteria

You've successfully completed TF-200 when you can:

- [ ] Design and create reusable modules
- [ ] Compose modules to build complex infrastructure
- [ ] Implement advanced deployment patterns
- [ ] Create YAML-driven configurations
- [ ] Import existing infrastructure into Terraform
- [ ] Safely refactor and migrate Terraform code
- [ ] Collaborate with teams using modules
- [ ] Document modules professionally
- [ ] Version modules semantically

---

## 🔄 What's Next?

### After TF-200

Once you complete TF-200, you're ready for:

1. **TF-300: Testing, Validation & Policy** (Advanced)
   - Input validation techniques
   - Pre/post conditions
   - Terraform test framework
   - Policy as code (OPA/Rego)

2. **Cloud Provider Modules** (Optional)
   - AWS-200: Apply concepts to AWS
   - AZ-200: Apply concepts to Azure
   - MC-300: Multi-cloud patterns

3. **Real-World Projects**:
   - Build a module library for your organization
   - Create multi-environment infrastructure
   - Implement GitOps workflows
   - Contribute to open-source modules

---

## 💡 Tips for Success

### Best Practices

1. **Start Simple**: Begin with small modules and grow complexity
2. **Document Everything**: Good documentation is as important as good code
3. **Version Properly**: Use semantic versioning for modules
4. **Test Thoroughly**: Test modules in isolation before composition
5. **Think Reusability**: Design for multiple use cases, not just one

### Common Pitfalls to Avoid

- ❌ Creating overly complex modules
- ❌ Not documenting module inputs/outputs
- ❌ Hardcoding values that should be variables
- ❌ Not versioning modules
- ❌ Skipping module testing
- ❌ Poor variable naming conventions

### Module Design Principles

1. **Single Responsibility**: Each module should do one thing well
2. **Composability**: Modules should work together seamlessly
3. **Flexibility**: Use variables and optional attributes
4. **Documentation**: Clear README with examples
5. **Versioning**: Semantic versioning for stability
6. **Testing**: Validate modules work as expected

---

## 📚 Additional Resources

### Official Documentation

- [Terraform Modules](https://www.terraform.io/language/modules)
- [Module Development](https://www.terraform.io/language/modules/develop)
- [Terraform Registry](https://registry.terraform.io/)
- [Module Composition](https://www.terraform.io/language/modules/develop/composition)
- [Import Blocks](https://www.terraform.io/language/import)

### Recommended Reading

- [Terraform Module Best Practices](https://www.terraform.io/language/modules/develop/best-practices)
- [Module Structure](https://www.terraform.io/language/modules/develop/structure)
- [Publishing Modules](https://www.terraform.io/language/modules/develop/publish)

### Community Modules

- [Terraform AWS Modules](https://github.com/terraform-aws-modules)
- [Azure Verified Modules](https://azure.github.io/Azure-Verified-Modules/)
- [Google Cloud Modules](https://github.com/terraform-google-modules)

---

## 🐛 Troubleshooting

### Common Issues

**Module Not Found**:
```bash
# Ensure module path is correct
terraform init

# For local modules, use relative paths
module "example" {
  source = "./modules/example"
}
```

**Module Version Conflicts**:
```bash
# Clear module cache
rm -rf .terraform/modules/
terraform init
```

**Import Failures**:
```bash
# Verify resource ID format
terraform import libvirt_domain.vm <domain-name>

# Check provider documentation for correct ID format
```

**State Migration Issues**:
```bash
# Always backup state before migration
terraform state pull > backup.tfstate

# Use moved blocks for safe refactoring
```

For detailed troubleshooting, see:
- Module-specific README files
- [Terraform Troubleshooting Guide](../docs/troubleshooting.md)

---

## 📊 Course Statistics

- **Total Modules**: 4
- **Total Sections**: 6
- **Hands-On Labs**: 20+
- **Code Examples**: 50+
- **Estimated Completion**: 6-15 hours

---

## 🎓 Real-World Applications

### What You Can Build

After TF-200, you can:

- **Module Libraries**: Create organization-wide module collections
- **Multi-Environment Infrastructure**: Dev, staging, production from one codebase
- **Self-Service Infrastructure**: Enable teams to deploy standardized infrastructure
- **GitOps Workflows**: Implement infrastructure CI/CD pipelines
- **Migration Projects**: Import and manage existing infrastructure
- **Enterprise Patterns**: Implement advanced deployment strategies

### Industry Use Cases

- **Startups**: Rapid infrastructure deployment with reusable modules
- **Enterprises**: Standardized infrastructure across teams
- **Consultancies**: Reusable modules for multiple clients
- **DevOps Teams**: Self-service infrastructure platforms
- **Cloud Migrations**: Import and manage existing resources

---

## 🤝 Contributing

Found an issue or want to improve the course?

- Report bugs via GitHub Issues
- Suggest improvements via Pull Requests
- Share your module designs
- Help other learners in Discussions

---

## 📜 License

This course is part of the hashi-training project and is licensed under the MIT License.

---

## 🙏 Acknowledgments

- HashiCorp for Terraform and module best practices
- The Terraform community for module patterns
- All contributors who help improve this course

---

**Ready to begin?** Start with [TF-201: Module Design & Composition](TF-201-module-design/README.md)

**Need a refresher?** Review [TF-100: Terraform Fundamentals](../TF-100-fundamentals/README.md)

**Questions?** Check the [Course Catalog](../docs/course-catalog.md) or [FAQ](../docs/faq.md)

---

*Last Updated: 2026-02-26*  
*Course Version: 3.0*  
*Terraform Version: 1.14+*

---

## 📦 Supplemental Content

The following topics were added after the initial course release to cover additional real-world patterns:

### TF-201 Additions
| Topic | Directory | Description |
|-------|-----------|-------------|
| `moved` blocks | `TF-201-module-design/moved-blocks/` | Rename/move resources and modules without `terraform state mv` (1.1+) |

### TF-203 Additions
| Topic | Directory | Description |
|-------|-----------|-------------|
| JSON-driven configuration | `TF-203-yaml-config/json-config/` | `jsondecode()` and `jsonencode()` alongside `yamldecode()` |

### TF-204 Additions
| Topic | Directory | Description |
|-------|-----------|-------------|
| `removed` blocks | `TF-204-import-migration/removed-blocks/` | Stop managing resources without destroying them (1.7+) |

---

*Last Updated: 2026-02-28*