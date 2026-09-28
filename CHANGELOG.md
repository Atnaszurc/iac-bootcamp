# Changelog

All notable changes to the HashiCorp Training Repository will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.5.0] - 2026-09-28

Updated for **Terraform 1.16** (verified with 1.16.4) with a preview of **Terraform 1.17** (verified with 1.17.0-beta2), and for **libvirt provider 0.9.9**.

### Added
- TF-301 Section 7: Capturing Ephemeral Values — `terraform_data` `store` block, `version` pinning and rotation (1.16+), with example and tests
- TF-307 hands-on actions example using the `hashicorp/local` `local_command` action — runs without cloud credentials, with tests
- TF-307 `query-example/` that validates with `terraform validate -query`
- TF-302 Section 3: `lifecycle { destroy = false }` on resources (1.16+), including how it differs from `prevent_destroy`
- TF-104: `terraform console -scope` (1.16+), `terraform state show -json` (1.16+), and a beta section on `terraform plan -minimal-refresh` (1.17)
- TF-305 Section 1: `terraform workspace list -json` (1.16+)
- libvirt examples: NAT/isolated networks with `forward`, `ips` and DHCP ranges; real VM IP outputs through `libvirt_domain_interface_addresses`
- libvirt tests: assertions that disks and network interfaces are actually present in the plan
- Hands-on libvirt examples with tests for TF-301 Sections 1-2 (validated VM inputs with cloud-init firewall rules; naming, subnet and image-age functions including `time` provider functions) and TF-302 Sections 1-2 (pre/postconditions on network, pool, disk, host and VM; an nginx health check with a scoped `http` data source)
- Moto (a local AWS API mock in Docker) for the few lessons no zero-cost provider can cover, each with a "Why Moto?" explanation: TF-305 Sections 2-3 (S3 backend: migration, `use_lockfile` locking, workspaces, `terraform_remote_state`), TF-307 (`terraform query` and generated config), TF-204 (identity-based import)
- TF-304: a libvirt configuration with a real `plan.json`, OPA 1.x policies (naming, resource limits with unit handling, networks with external data) plus a shared helper package, 36 policy tests at 100% coverage, Regal configuration, and two labs with verified solutions
- TF-405: a minimal Stack (2 resources under management in total) that validates locally with `terraform stacks validate`, component tests, and a costed "building it out" exercise with an OIDC-authenticated S3 bucket
- `scripts/run-tests.sh` runs the TF-304 policy tests (when `opa` is installed) and the TF-405 component tests

### Changed
- TF-202 Section 2 (canary / blue-green) redesigned for libvirt: deployment pools as a `for_each` map, an HAProxy config with per-pool weights for real traffic splitting, and in-place pool rolls with `create_before_destroy` using `random_id` generations so replacements get unique names. The previous README was an Azure lesson that didn't match its libvirt example.
- TF-103 Sections 1-3 and TF-104 Section 3 rewritten from Azure to libvirt so the instructions match their examples
- All libvirt code in the READMEs updated to provider 0.9.x (38 blocks in 15 files), and verified against the provider schema; the build-along labs in TF-103, TF-201, TF-203 and TF-204 were applied on a real libvirt host
- TF-201: network module uses conditional nested attributes instead of `dynamic` blocks; the complete-VM module accepts an existing `network_name` so the 3-tier solution no longer creates overlapping networks
- TF-204: import flow uses UUIDs (libvirt doesn't import by name), generates config from `import` blocks alone, and explains the provider's read-back gaps and `ignore_changes`
- TF-303: every libvirt example and lab now passes `terraform test`, including a real integration test; mock files only mock computed attributes
- TF-304 rewritten for OPA 1.x (tested with 1.21.0) following the Rego style guide: 1.x syntax and migration, the plan JSON as input, undefined values, testing and linting, `deny`/`warn` in CI, and OPA vs Sentinel vs Terraform policy in HCP Terraform (policies work with HCP Terraform's `input.plan` wrapper; the Sentinel example was run with the Sentinel CLI)
- TF-405 rewritten for Stacks GA: `.tfcomponent.hcl` files, `.terraform-version`, lock file, the built-in `terraform` provider for `terraform_data`, the real `terraform stacks` commands, deployment groups, and resources-under-management cost
- TF-104 Section 6 (backend validation) rewritten around what `terraform validate` actually checks
- TF-302 Section 4 uses the `tls` provider's `private_key_pem_wo` throughout, and Section 5 real deprecations in the `random` and `null` providers
- AWS and Azure snippets outside `cloud-modules/` replaced with libvirt, `tls` or `terraform_data` equivalents (TF-101, TF-104 Section 4, TF-301 Sections 5-6, TF-302 Section 4, TF-306 Section 4)
- `docs/libvirt-setup.md`: how to create the `default` storage pool many examples rely on
- TF-307 rewritten: correct `action` syntax (`config {}` plus `lifecycle.action_trigger` on the resource), valid event names, query files without a `terraform` block, provider arguments inside `list` `config {}`; covers destroy-time events, `on_failure` and `caller` (1.16+)
- CI examples and `docs/testing.md` now pin Terraform `~1.16`
- `workspace list` output examples now show the real (alphabetical) order

### Fixed
- **libvirt VM examples never attached disks or NICs.** The examples used `devices.disk`/`interface`/`console`, but the 0.9.x schema uses `disks`/`interfaces`/`consoles`. Terraform silently drops unknown keys inside nested attributes, so `validate` and the mocked tests passed while real VMs would have had no disks or network. The examples also passed megabytes to `memory` (KiB by default) and never started the VM (`running` defaults to false). All 7 VM configurations are fixed and were applied against a real libvirt host.
- Module `ip_address` outputs returned a placeholder string instead of an IP
- `network_cidr` inputs in TF-104 Section 3 and TF-203 were accepted but never used
- Tests in TF-202 and TF-203 planned against the real libvirt provider instead of a mock
- Broken links to `docs/base-images.md`
- TF-104: examples 3 and 4 of the backend validation lesson expected `terraform validate` to reject a missing `bucket` and an empty `workspace_key_prefix`; it doesn't. Argument checks were in 1.15.0 only and removed in 1.15.1 because they broke `-backend-config`; `terraform init` checks the arguments
- TF-301 Section 6 said an output with `type = string` fails for a number; Terraform converts it, and only fails for values it can't convert
- TF-304: the example plan JSON was hand-written (it gave `local_file` a `tags` attribute), 15 of 23 README policies failed `opa check` on OPA 1.x, and the resource-limit policies read libvirt memory as MiB regardless of `memory_unit`
- TF-405: the example used `.tfstack.hcl` files, which Stacks no longer read, invented `terraform stacks plan`/`apply` commands, and never passed its OIDC token to the provider
- TF-204 identity import: `aws_s3_bucket_acl`'s identity has no `acl` attribute, and the quoted "does not support identity" error didn't exist; both replaced with verified examples and errors
- `terraform query -generate-config` in the docs is `-generate-config-out` in Terraform

### Removed
- Committed `tfplan` binary (TF-301 Section 6) and Sentinel binary, EULA and terms files (MC-303)
- Legacy `terraform.tfstate` files in TF-202 examples
- TF-405's AWS networking, database and compute components (5 deployments of about 23 billable resources each)
- TF-304's `policies/` and `tests/` (replaced by `policy/`)

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