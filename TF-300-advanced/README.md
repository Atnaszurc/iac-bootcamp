# TF-300: Testing, Validation & Policy

**Level**: 300 (Advanced)
**Duration**: 8 hours
**Prerequisites**: TF-200 series (Terraform Modules & Patterns)
**Platform**: Libvirt (local VMs)

---

## 🎯 Course Overview

Welcome to **TF-300: Testing, Validation & Policy**! This advanced course teaches you how to build **robust, production-ready infrastructure** through comprehensive validation, testing, and policy enforcement. You'll learn to catch errors before deployment, validate infrastructure at runtime, and enforce organizational policies.

This course focuses on **quality assurance**, **reliability**, and **governance** for Terraform infrastructure.

---

## 📚 What You'll Learn

### Core Competencies

After completing TF-300, you will be able to:

- ✅ **Validate Inputs Comprehensively**: Implement robust variable validation with custom rules
- ✅ **Use Advanced Functions**: Master try(), can(), and provider-defined functions
- ✅ **Implement Runtime Validation**: Use preconditions, postconditions, and check blocks
- ✅ **Write Infrastructure Tests**: Create automated tests for Terraform modules
- ✅ **Enforce Policies**: Implement policy as code with OPA/Rego
- ✅ **Prevent Errors**: Catch configuration issues before deployment
- ✅ **Build Reliable Infrastructure**: Create self-validating, robust configurations

---

## 🗂️ Course Modules

### TF-301: Input Validation & Advanced Functions
**Duration**: 1.5 hours  
**Directory**: `TF-301-validation/`

Implement comprehensive input validation and master advanced Terraform functions for error handling and capability testing.

**Topics**:
- **1-variable-conditions/**: Variable validation blocks
  - Validation syntax (Terraform 1.14+)
  - Condition expressions
  - Custom error messages
  - Cross-variable validation
  - Complex validation logic
  - Regex patterns
  - Type checking

- **2-advanced-functions/**: Advanced function usage
  - `try()` for error handling
  - `can()` for capability testing
  - Type conversion functions
  - Provider-defined functions (Azure)
  - Conditional logic patterns
  - Error recovery strategies

**Hands-On**:
- Write validation rules for IP addresses, CIDR blocks
- Implement cross-variable validation
- Use try() for graceful error handling
- Test capability with can()
- Create helpful, actionable error messages
- Validate complex data structures

**Key Skills**:
- Comprehensive input validation
- Advanced function usage
- Error handling patterns
- Validation best practices

---

### TF-302: Pre/Post Conditions & Check Blocks
**Duration**: 1.5 hours  
**Directory**: `TF-302-conditions-checks/`

Implement runtime validation with preconditions, postconditions, and check blocks to ensure infrastructure correctness throughout its lifecycle.

**Topics**:
- **1-pre-postconditions/**: Lifecycle validation
  - Preconditions (validate before operations)
  - Postconditions (validate after operations)
  - Resource lifecycle validation
  - Data source validation
  - Output validation
  - Error handling strategies
  - Best practices

- **2-check-blocks/**: Continuous validation
  - Check block syntax (Terraform 1.5+)
  - Data source checks
  - HTTP endpoint checks
  - Custom validation checks
  - Continuous monitoring
  - Check block organization

**Hands-On**:
- Implement preconditions on VM resources
- Add postconditions to verify resource state
- Create check blocks for infrastructure monitoring
- Validate data sources
- Test validation failures
- Build comprehensive validation strategies

**Key Skills**:
- Precondition implementation
- Postcondition validation
- Check block usage
- Runtime validation strategies

---

### TF-303: Terraform Test Framework
**Duration**: 1 hour  
**Directory**: `TF-303-test-framework/`

Learn to write automated tests for Terraform modules using the native test framework introduced in Terraform 1.6+.

**Topics** (Planned):
- Terraform test framework basics
- Writing test files (.tftest.hcl)
- Test assertions and expectations
- Integration testing
- Mocking and test doubles
- Test organization
- CI/CD integration
- Test-driven infrastructure development

**Hands-On** (Planned):
- Write unit tests for modules
- Create integration tests
- Test module composition
- Implement test assertions
- Run tests in CI/CD pipelines
- Practice test-driven development

**Status**: ✅ Complete (every libvirt example and lab passes `terraform test`)

---

### TF-304: Policy as Code - OPA/Rego
**Duration**: 1.5 hours
**Directory**: `TF-304-policy-code/`
**Needs**: OPA 1.x (Terraform and libvirt only to make your own plans)

Implement policy as code using Open Policy Agent (OPA) and Rego to enforce organizational standards and compliance requirements.

**Topics**:
- Policy vs validation and conditions
- Rego in the OPA 1.x syntax, and migrating old policies
- The Terraform plan JSON as policy input
- Undefined values and the "silent pass" bug
- Policy testing with `opa test`, coverage, and linting with Regal
- Enforcement: `deny`/`warn`, CI gates, and HCP Terraform (OPA, Sentinel, Terraform policy)

**Hands-On**:
- Evaluate policies against a real libvirt plan (naming, resource limits in the right units, networks)
- Fix a plan until it passes, and make your own plans
- Write a policy test-first (qcow2 volumes)
- Protect production VMs from deletes and replacements

**Key Skills**:
- OPA/Rego policy development
- Terraform plan analysis
- Policy testing strategies
- CI/CD integration patterns

**Status**: ✅ Complete with 2 policies and 15 passing tests

---

### TF-306: Terraform Functions Deep Dive
**Duration**: 1.5 hours
**Directory**: `TF-306-functions/`

A systematic deep dive into four essential function categories — string manipulation, collection transformation, filesystem operations, and data encoding. Master the building blocks of production-grade Terraform code.

**Topics**:
- **1-string-functions/**: Advanced string manipulation
  - `format()` / `formatlist()` — printf-style formatting
  - `regex()` / `regexall()` — pattern matching
  - `replace()`, `split()`, `join()`, `substr()`
  - `trim()`, `trimprefix()`, `trimsuffix()`
  - Real-world naming convention patterns

- **2-collection-functions/**: Collection transformation
  - `flatten()` — collapse nested lists
  - `merge()` — combine maps
  - `setproduct()` — cartesian product for deployment matrices
  - `zipmap()` — build maps from key/value lists
  - `distinct()`, `compact()`, `concat()`

- **3-filesystem-functions/**: External file loading
  - `file()` — read raw file contents
  - `templatefile()` — render `.tftpl` templates with loops/conditionals
  - `fileset()` — discover files by glob pattern
  - `filebase64()` — binary-safe file encoding
  - `path.module` / `path.root` / `path.cwd`

- **4-encoding-functions/**: Data format conversion
  - `jsonencode()` / `jsondecode()` — HCL ↔ JSON
  - `yamlencode()` / `yamldecode()` — HCL ↔ YAML
  - `base64encode()` / `base64decode()` — binary-safe encoding
  - `tostring()`, `tonumber()`, `tobool()` — type coercion
  - `toset()`, `tolist()`, `tomap()` — collection type conversion

**Hands-On**:
- Build consistent resource naming with `format()` and `lower()`
- Generate multi-region deployment matrices with `setproduct()`
- Render cloud-init configs with `templatefile()` loops
- Generate IAM policies dynamically with `jsonencode()` + `for`
- Load YAML config directories with `fileset()` + `yamldecode()`

**Key Skills**:
- Advanced function composition
- Template-driven configuration
- Dynamic policy generation
- Config directory patterns

---

### TF-307: List Resources, terraform query & Actions ✨ NEW — Terraform 1.14+
**Duration**: 1.5 hours
**Directory**: `TF-307-query-actions/`

Covers two new Terraform 1.14 features that extend the Terraform workflow beyond traditional CRUD: **list resources** for infrastructure discovery, and **actions** for provider-defined imperative operations.

**Topics**:
- **Part 1 — List Resources & terraform query**:
  - `.tfquery.hcl` file format (only `list`, `provider`, `variable`, `locals` blocks)
  - `list` block syntax — provider arguments inside `config {}`, `include_resource`, `limit`
  - `terraform query` command and `terraform validate -query`
  - `terraform query -generate-config-out` for import generation
  - List resources vs data sources — comparison and use cases
  - Bulk import workflow: search → generate → import → clean up

- **Part 2 — Actions**:
  - `action` block syntax with a `config {}` block
  - Triggers via `lifecycle { action_trigger { ... } }` on the resource
  - Events: `before_create`, `after_create`, `before_update`, `after_update`, plus `before_destroy` and `after_destroy` (1.16+)
  - `on_failure = halt | continue | taint` (1.16+)
  - The `caller` symbol for reusing one action across resource instances (1.16+)
  - Manual invocation with `terraform plan/apply -invoke`
  - Actions vs `local-exec` vs `terraform_data` — when to use each

**Hands-On**:
- Discover and bulk-import "forgotten" EC2 instances and S3 buckets with `terraform query` (against Moto, a local AWS mock in Docker)
- Wire `local_command` actions to create, update and destroy events (no credentials needed)
- Invoke an action manually and experiment with `on_failure`
- Read real-world AWS action patterns: Lambda warm-up, DynamoDB backup before destroy, CloudFront invalidation

**Key Skills**:
- Infrastructure discovery and import automation
- Provider-defined imperative operations
- Modern alternatives to `null_resource` + `local-exec`

> **Note**: Both features require provider support. The actions hands-on uses the `hashicorp/local` provider's `local_command` action (2.6.0+), so it runs anywhere. The query hands-on uses the real AWS provider against Moto, an open-source AWS mock running in Docker, because only the big cloud providers implement list resources. No AWS account needed.

---

### TF-305: Workspaces & Remote State
**Duration**: 1.5 hours
**Directory**: `TF-305-workspaces-remote-state/`

Master state management for teams and production environments — moving beyond local state to remote backends, workspace strategies, and HCP Terraform.

**Topics**:
- **1-workspaces/**: CLI workspace management
  - `terraform workspace` commands
  - `terraform.workspace` interpolation
  - Workspace-driven configuration
  - Anti-pattern: workspaces ≠ environments

- **2-remote-backends/**: Remote state backends
  - HCP Terraform `cloud` block
  - Azure Blob Storage (`azurerm`)
  - AWS S3 + DynamoDB (`s3`)
  - State locking comparison

- **3-remote-state-sharing/**: Cross-configuration state
  - `terraform_remote_state` data source
  - Layered infrastructure architecture
  - Producer/consumer pattern
  - Coupling best practices

- **4-hcp-terraform-state/**: HCP Terraform as recommended backend
  - Free tier (500 resources)
  - State history and rollback
  - Migrating from local state
  - HCP workspaces vs CLI workspaces

**Hands-On**:
- Create and switch between workspaces
- Configure a remote backend
- Share state between two configurations
- Migrate local state to HCP Terraform
- View state history in HCP Terraform UI

**Key Skills**:
- Remote state management
- Team collaboration patterns
- State locking and history
- Layered infrastructure design

---

## 🎓 Learning Path

### Recommended Progression

```
Week 1: Validation Fundamentals
├── Day 1-2: TF-301 (Input Validation & Advanced Functions)
└── Day 3-4: TF-302 (Pre/Post Conditions & Check Blocks)

Week 2: Testing, Policy & State Management
├── Day 1-2: TF-303 (Terraform Test Framework)
├── Day 3:   TF-304 (Policy as Code - OPA/Rego)
├── Day 4-5: TF-305 (Workspaces & Remote State)
└── Day 6:   TF-306 (Terraform Functions Deep Dive)

Week 3: New Terraform 1.14 Features
└── Day 1:   TF-307 (List Resources, terraform query & Actions)
```

### Current Status

- ✅ **TF-301**: Complete and ready
- ✅ **TF-302**: Complete and ready
- ✅ **TF-303**: Complete and ready
- ✅ **TF-304**: Complete and ready (OPA 1.x, 36 policy tests)
- ✅ **TF-305**: Complete and ready
- ✅ **TF-306**: Complete and ready
- ✅ **TF-307**: Complete and ready (Terraform 1.14+)

### Time Commitment

- **Currently Available**: 10 hours (all seven modules)
- **With Practice**: 12-14 hours (recommended)
- **Full Mastery**: 18-20 hours (includes experimentation)

---

## 🚀 Getting Started

### Prerequisites

Before starting TF-300, you must have:

1. **Completed TF-200**: All four modules (TF-201 through TF-204)
2. **Comfortable with**:
   - Module design and composition
   - Advanced Terraform patterns
   - YAML-driven configuration
   - Import and migration strategies
   - Complex Terraform configurations

3. **System Requirements**:
   - Same as previous courses (Libvirt + Terraform installed)
   - Terraform 1.5+ (for check blocks)
   - Terraform 1.14+ (for latest validation features)

### Quick Start

```bash
# 1. Navigate to the course directory
cd hashi-training/TF-300-advanced

# 2. Start with TF-301
cd TF-301-validation
cat README.md

# 3. Follow the exercises in order
# Each module builds on previous knowledge
```

---

## 📖 Course Materials

### What's Included

Each module contains:

- **README.md**: Detailed explanations and learning objectives
- **Subdirectories**: Organized by topic
- **example/**: Working Terraform configurations
- **Exercises**: Hands-on labs to practice concepts
- **Best Practices**: Industry-standard validation patterns

### Directory Structure

```
TF-300-advanced/
├── README.md                          # This file
├── TF-301-validation/
│   ├── README.md                      # Module overview
│   ├── 1-variable-conditions/         # Variable validation
│   ├── 2-advanced-functions/          # Advanced functions
│   └── 3-sensitive-values/            # Sensitive variables & nonsensitive()
├── TF-302-conditions-checks/
│   ├── README.md                      # Module overview
│   ├── 1-pre-postconditions/          # Lifecycle validation
│   ├── 2-check-blocks/                # Check blocks
│   └── 3-lifecycle-arguments/         # create_before_destroy, ignore_changes, etc.
├── TF-303-test-framework/
│   ├── README.md                      # The terraform test framework
│   └── example/                       # Tests with mocks, overrides and a real integration run
├── TF-304-policy-code/
│   ├── README.md                      # Policy as code with OPA/Rego
│   └── example/                       # libvirt config, real plan.json, policies + tests
├── TF-305-workspaces-remote-state/
│   ├── README.md                      # Course overview
│   ├── 1-workspaces/                  # CLI workspaces
│   ├── 2-remote-backends/             # Remote backend config
│   ├── 3-remote-state-sharing/        # terraform_remote_state
│   └── 4-hcp-terraform-state/         # HCP Terraform backend
└── TF-306-functions/
    ├── README.md                      # Course overview
    ├── 1-string-functions/            # format, regex, replace, split, join
    ├── 2-collection-functions/        # flatten, merge, setproduct, zipmap
    ├── 3-filesystem-functions/        # file, templatefile, fileset
    └── 4-encoding-functions/          # jsonencode, yamlencode, base64encode
```

---

## 🎯 Learning Objectives

### By Module

#### After TF-301, you will:
- Write comprehensive variable validation rules
- Implement cross-variable validation
- Use try() for error handling
- Use can() for capability testing
- Master advanced Terraform functions
- Create helpful, actionable error messages
- Validate complex data structures

#### After TF-302, you will:
- Implement preconditions on resources
- Implement postconditions on resources
- Use check blocks for continuous validation
- Understand when to use each validation type
- Create comprehensive validation strategies
- Handle validation failures gracefully
- Build self-validating infrastructure

#### After TF-306, you will:
- Apply advanced string functions for naming and text processing
- Transform collections with flatten, merge, setproduct, and zipmap
- Load external configuration using file, templatefile, and fileset
- Convert data between JSON, YAML, and Base64 formats
- Combine multiple functions to solve real infrastructure problems
- Use terraform console to test functions interactively

#### After TF-303, you will:
- Write automated tests for Terraform modules
- Create test assertions
- Implement integration tests
- Use test-driven development
- Run tests in CI/CD pipelines
- Mock external dependencies

#### After TF-304, you will:
- Write policies in Rego language
- Enforce organizational standards with OPA
- Implement compliance checks for Terraform plans
- Test policies effectively with OPA test framework
- Integrate policies into CI/CD workflows
- Understand the difference between OPA and Sentinel

---

## 🏆 Success Criteria

You've successfully completed TF-300 (current content) when you can:

- [ ] Write comprehensive variable validation rules
- [ ] Use try() and can() functions effectively
- [ ] Implement preconditions on resources
- [ ] Implement postconditions on resources
- [ ] Create check blocks for monitoring
- [ ] Understand when to use each validation type
- [ ] Build self-validating infrastructure
- [ ] Provide helpful error messages
- [ ] Prevent common configuration errors

---

## 🔄 What's Next?

### After TF-300

Once you complete TF-300, you're ready for:

1. **PKR-100: Packer Fundamentals**
   - Build custom VM images
   - Automate image creation
   - Use Ansible for configuration
   - Integrate with Terraform

2. **Cloud Provider Modules** (Optional)
   - AWS-200: Apply concepts to AWS
   - AZ-200: Apply concepts to Azure
   - MC-300: Multi-cloud patterns

3. **Real-World Projects**:
   - Build production-ready infrastructure
   - Implement CI/CD pipelines
   - Create self-service platforms
   - Contribute to open-source projects

4. **Advanced Topics**:
   - GitOps workflows
   - Infrastructure testing strategies
   - Compliance automation
   - Enterprise Terraform patterns

---

## 💡 Tips for Success

### Best Practices

1. **Validate Early**: Catch errors at input validation, not at apply time
2. **Provide Context**: Error messages should explain what's wrong and how to fix it
3. **Layer Validation**: Use input validation, preconditions, postconditions, and checks
4. **Test Validation**: Ensure your validation logic works as expected
5. **Document Validation**: Explain why validation rules exist

### Common Pitfalls to Avoid

- ❌ Over-validating (making configurations too rigid)
- ❌ Under-validating (allowing invalid configurations)
- ❌ Cryptic error messages
- ❌ Not testing validation logic
- ❌ Validating at the wrong lifecycle stage
- ❌ Ignoring validation failures

### Validation Strategy

1. **Input Validation**: Validate variables before use
2. **Preconditions**: Validate before resource operations
3. **Postconditions**: Validate after resource operations
4. **Check Blocks**: Continuous validation and monitoring
5. **Tests**: Automated testing of modules
6. **Policies**: Organizational standards enforcement

---

## 📚 Additional Resources

### Official Documentation

- [Variable Validation](https://www.terraform.io/language/values/variables#custom-validation-rules)
- [Preconditions and Postconditions](https://www.terraform.io/language/expressions/custom-conditions)
- [Check Blocks](https://www.terraform.io/language/checks)
- [Terraform Test](https://www.terraform.io/language/tests)
- [Functions Reference](https://www.terraform.io/language/functions)

### Recommended Reading

- [Custom Conditions](https://www.terraform.io/language/expressions/custom-conditions)
- [Error Handling](https://www.terraform.io/language/expressions/type-constraints)
- [Testing Terraform](https://www.terraform.io/language/tests)

### Community Resources

- [Terraform Best Practices](https://www.terraform-best-practices.com/)
- [OPA Documentation](https://www.openpolicyagent.org/docs/)
- [Sentinel Documentation](https://docs.hashicorp.com/sentinel)

---

## 🐛 Troubleshooting

### Common Issues

**Validation Failures**:
```bash
# Review validation error messages carefully
# They indicate what's wrong and often how to fix it

# Test validation logic in terraform console
terraform console
> var.example_variable
```

**Check Block Failures**:
```bash
# Check blocks don't prevent apply, they warn
# Review check output after apply
terraform apply

# Check blocks run during plan and apply
terraform plan
```

**Function Errors**:
```bash
# Test functions in terraform console
terraform console
> try(var.maybe_null, "default")
> can(regex("^[0-9]+$", var.value))
```

For detailed troubleshooting, see:
- Module-specific README files
- [Terraform Troubleshooting Guide](../docs/troubleshooting.md)

---

## 📊 Course Statistics

- **Total Modules**: 7 (6 complete, 1 planned)
- **Available Content**: 6 modules (TF-301, TF-302, TF-304, TF-305, TF-306, TF-307)
- **Hands-On Labs**: 35+ (current), 45+ (when complete)
- **Code Examples**: 70+ (current), 90+ (when complete)
- **Estimated Completion**: 8.5 hours (current), 9.5 hours (when complete)

---

## 🎓 Real-World Applications

### What You Can Build

After TF-300, you can:

- **Self-Validating Infrastructure**: Configurations that catch errors automatically
- **Production-Ready Modules**: Modules with comprehensive validation
- **Compliance Automation**: Enforce standards through policy
- **Reliable Deployments**: Reduce deployment failures through validation
- **Quality Gates**: Implement validation in CI/CD pipelines
- **Self-Service Platforms**: Enable teams with guardrails

### Industry Use Cases

- **Enterprises**: Enforce security and compliance standards
- **DevOps Teams**: Reduce deployment failures
- **Platform Teams**: Build self-service infrastructure with guardrails
- **Consultancies**: Deliver high-quality, validated infrastructure
- **Regulated Industries**: Automate compliance checks

---

## 🤝 Contributing

Found an issue or want to improve the course?

- Report bugs via GitHub Issues
- Suggest improvements via Pull Requests
- Share your validation patterns
- Suggest new labs and policy examples
- Help other learners in Discussions

---

## 📜 License

This course is part of the hashi-training project and is licensed under the MIT License.

---

## 🙏 Acknowledgments

- HashiCorp for Terraform validation features
- The Terraform community for validation patterns
- OPA community for policy as code
- All contributors who help improve this course

---

**Ready to begin?** Start with [TF-301: Input Validation & Advanced Functions](TF-301-validation/README.md)

**Need a refresher?** Review [TF-200: Terraform Modules & Patterns](../TF-200-modules/README.md)

**Questions?** Check the [Course Catalog](../docs/course-catalog.md) or [FAQ](../docs/faq.md)

---

*Last Updated: 2026-02-28*
*Course Version: 3.1*
*Terraform Version: 1.14+*
*Status: Partial (4 of 6 modules complete)*