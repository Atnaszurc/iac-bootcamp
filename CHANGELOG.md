# Changelog

All notable changes to the HashiCorp Training Repository will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.4.0] - 2026-05-25

### Added
- IBM Cloud (IBM-200) training modules with comprehensive examples and tests
  - IBM-201: Setup & Authentication - Provider configuration and resource group management
  - IBM-202: Compute & Networking - VPC, subnets, and virtual server instances
  - IBM-203: Security & Storage - Security groups, Key Protect, and Cloud Object Storage
  - IBM-204: Advanced Patterns - Multi-tier architecture with load balancers
- IBM-200 integration into automated test framework (`scripts/run-tests.sh`)
- Complete test coverage for all IBM Cloud modules using mock providers (15 tests, 19 run blocks)
- Documentation updates for IBM Cloud in main cloud-modules README
- CHANGELOG.md to track version history and changes

### Changed
- Updated `scripts/run-tests.sh` to include IBM-200 test paths and documentation
- Enhanced cloud-modules README with IBM Cloud comparison and learning paths

## [1.3.1] - 2026-05-07

### Changed
- Updated all examples and documentation for Terraform 1.15 compatibility
- Refreshed provider versions and configurations across all modules
- Updated test framework to leverage Terraform 1.15 features

**Note**: This was incorrectly tagged as v1.15.0 in git history. The training repository version is now decoupled from Terraform versions to avoid confusion.

## [1.3.0] - 2026-03-24

### Changed
- Updated main README.md with improved documentation structure
- Enhanced getting started instructions and prerequisites

## [1.2.0] - 2026-03-19

### Added
- Google Cloud Platform (GCP-200) training modules
  - GCP-201: Setup & Authentication
  - GCP-202: Compute & Networking
  - GCP-203: Security & Storage
  - GCP-204: Advanced Patterns
- Complete test coverage for GCP modules using mock providers
- GCP integration into automated test framework

### Changed
- Updated cloud-modules documentation to include GCP
- Enhanced multi-cloud comparison tables

## [1.1.1] - 2026-03-04

### Removed
- AWS Provider v6 upgrade guide (consolidated into main documentation)

### Changed
- Updated documentation for WSL2 requirements on Windows
- Clarified system prerequisites across all modules

## [1.1.0] - 2026-03-04

### Added
- TF-405: Terraform Stacks example demonstrating component-based infrastructure
- Enhanced policy examples across TF-400 series modules

### Changed
- Updated READMEs to reflect completed policy examples
- Improved documentation structure for HCP Terraform modules

## [1.0.0] - 2026-03-03

### Added
- Initial release of complete Terraform & Packer training repository
- **Core Terraform Training (TF-100 through TF-400)**:
  - TF-100: Fundamentals (Intro, Variables, Infrastructure, State & CLI)
  - TF-200: Modules & Patterns (Design, Advanced Patterns, YAML Config, Import/Migration)
  - TF-300: Advanced (Validation, Conditions, Testing, Provisioners, Workspaces, Functions)
  - TF-400: HCP Terraform (Workspaces, VCS, Policy, Sentinel, Stacks)
- **Cloud Provider Modules**:
  - AWS-200: Complete AWS training series (4 modules)
  - AZ-200: Complete Azure training series (4 modules)
  - MC-300: Multi-cloud patterns (4 modules)
- **Packer Training**:
  - PKR-100: Fundamentals
  - PKR-200: Advanced patterns
- **Instruqt Labs**: Interactive hands-on labs for core concepts
- **Test Framework**: Automated testing with `scripts/run-tests.sh`
  - Support for local/libvirt providers (core training)
  - Support for mock providers (cloud modules)
  - Zero-cost validation for all examples
- **Documentation**: Comprehensive READMEs, learning paths, and prerequisites
- **Development Tools**: Scripts for testing, validation, and automation

### Features
- 100+ working Terraform examples across all skill levels
- Mock provider support for cloud modules (no credentials required)
- Automated test coverage for all testable examples
- Progressive learning path from fundamentals to advanced topics
- Multi-cloud architecture patterns and best practices
- Integration with HCP Terraform for enterprise workflows

---

## Version History Summary

- **1.4.0** (2026-05-25): IBM Cloud modules and CHANGELOG added
- **1.3.1** (2026-05-07): Terraform 1.15 compatibility updates (was incorrectly tagged as v1.15.0)
- **1.3.0** (2026-03-24): Documentation improvements
- **1.2.0** (2026-03-19): GCP modules added
- **1.1.1** (2026-03-04): Documentation cleanup
- **1.1.0** (2026-03-04): Stacks and policy examples
- **1.0.0** (2026-03-03): Initial release

**Versioning Note**: This project follows [Semantic Versioning](https://semver.org/) for training content, independent of Terraform version numbers. Major version changes indicate breaking changes to course structure, minor versions add new modules or significant content, and patches fix bugs or update documentation.

---

## Contributing

When adding new features or modules, please:
1. Update this CHANGELOG.md under the [Unreleased] section
2. Follow the Keep a Changelog format (Added, Changed, Deprecated, Removed, Fixed, Security)
3. Include test coverage for new examples
4. Update relevant README files
5. Add new test paths to `scripts/run-tests.sh` if applicable

## Links

- [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
- [Semantic Versioning](https://semver.org/spec/v2.0.0.html)
- [HashiCorp Terraform Documentation](https://developer.hashicorp.com/terraform)