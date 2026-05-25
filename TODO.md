# TODO: Add IBM Cloud Module to `hashi-training/iac-bootcamp`

## Goal

Add an IBM Cloud optional module to the course that matches the **structure, depth, teaching flow, and artifact layout** of the existing cloud provider modules:

- `cloud-modules/AWS-200-terraform`
- `cloud-modules/AZ-200-terraform`
- `cloud-modules/GCP-200-terraform`

This TODO is intentionally **research-first**. The first phase is to iteratively inspect one existing cloud module at a time, extract what it teaches and which Terraform resources it uses, and then identify the correct IBM Cloud equivalents from `documentation/terraform-provider-ibm`.

---

## Working assumptions

- IBM Cloud should likely become a new optional module under `cloud-modules/`, with a course numbering scheme aligned to existing provider modules.
- The existing provider modules follow a common 4-part structure:
  - `201` setup / authentication / provider basics
  - `202` compute + networking
  - `203` security + storage
  - `204` advanced patterns
- IBM Cloud should prioritize **modern IBM VPC and managed-service resources**, not older Classic-first patterns, unless parity analysis shows a gap.
- We should use the IBM provider documentation and examples in `documentation/terraform-provider-ibm` as the source of truth for supported resources and realistic example patterns.

---

## Phase 1 - Establish parity baseline from existing cloud modules

### 1.1 Document the structural contract of existing cloud modules
- [ ] Confirm the directory and file layout of each existing provider module:
  - [ ] AWS
  - [ ] Azure
  - [ ] GCP
- [ ] Record the standard artifact pattern used in each course unit:
  - [ ] `README.md`
  - [ ] `example/main.tf`
  - [ ] `example/variables.tf`
  - [ ] `example/outputs.tf` where present
  - [ ] `example/tests/basic.tftest.hcl`
  - [ ] `terraform.tfvars.example` or equivalent, if present
- [ ] Record naming conventions for:
  - [ ] module folder names
  - [ ] lesson folder names
  - [ ] resource labels
  - [ ] variable names
  - [ ] output names
  - [ ] test file names

### 1.2 Scan AWS module first and extract teaching scope
- [ ] Inspect `AWS-201-setup-auth`
  - [ ] List resources/data sources used
  - [ ] Summarize concepts taught
  - [ ] Capture expected learner outcomes
- [ ] Inspect `AWS-202-compute-networking`
  - [ ] List resources/data sources used
  - [ ] Separate “must-have” concepts from “provider-specific extras”
- [ ] Inspect `AWS-203-security-storage`
  - [ ] List resources/data sources used
  - [ ] Identify IAM, storage, encryption, and disk concepts
- [ ] Inspect `AWS-204-advanced-patterns`
  - [ ] List resources/data sources used
  - [ ] Identify autoscaling, load balancing, and templating concepts
- [ ] Produce an AWS parity summary table:
  - [ ] lesson
  - [ ] concept
  - [ ] Terraform resources
  - [ ] required supporting files

### 1.3 Scan Azure module second and extract teaching scope
- [ ] Inspect `AZ-201-setup-auth`
- [ ] Inspect `AZ-202-compute-networking`
- [ ] Inspect `AZ-203-security-storage`
- [ ] Inspect `AZ-204-advanced-patterns`
- [ ] Produce an Azure parity summary table:
  - [ ] lesson
  - [ ] concept
  - [ ] Terraform resources
  - [ ] required supporting files

### 1.4 Scan GCP module third and extract teaching scope
- [ ] Inspect `GCP-201-setup-auth`
- [ ] Inspect `GCP-202-compute-networking`
- [ ] Inspect `GCP-203-security-storage`
- [ ] Inspect `GCP-204-advanced-patterns`
- [ ] Produce a GCP parity summary table:
  - [ ] lesson
  - [ ] concept
  - [ ] Terraform resources
  - [ ] required supporting files

### 1.5 Normalize cross-cloud teaching expectations
- [ ] Build a provider-agnostic comparison matrix with these columns:
  - [ ] lesson number
  - [ ] core topic
  - [ ] AWS implementation
  - [ ] Azure implementation
  - [ ] GCP implementation
  - [ ] common denominator concept
- [ ] Mark concepts as one of:
  - [ ] mandatory parity item
  - [ ] optional enhancement
  - [ ] provider-specific variation
- [ ] Identify where the existing providers already differ in scope so IBM can align to the actual pattern, not an assumed perfect symmetry

---

## Phase 2 - Map IBM Cloud equivalents from provider docs

### 2.1 Build IBM provider reference shortlist
- [ ] Identify the IBM documentation/example directories most relevant to each lesson area:
  - [ ] provider/authentication
  - [ ] VPC networking
  - [ ] compute / VSI
  - [ ] object storage
  - [ ] key management
  - [ ] secrets
  - [ ] load balancing
  - [ ] instance templates / instance groups / autoscaling
  - [ ] database services
- [ ] Create a scratch mapping table: `existing cloud concept -> candidate IBM resources`
- [ ] Note any IBM concepts that require an additional foundational resource not present in other clouds, such as `ibm_resource_instance`

### 2.2 Map setup/authentication lesson equivalents
- [ ] Determine what IBM lesson `201` should teach:
  - [ ] provider configuration
  - [ ] authentication model
  - [ ] region / zone selection
  - [ ] resource group usage
  - [ ] identity / account introspection data sources
- [ ] Confirm which IBM resources/data sources best fit the setup lesson
- [ ] Decide whether IBM `201` should:
  - [ ] remain mostly configuration-focused like AWS/Azure
  - [ ] include a small bootstrap resource like GCP
- [ ] Capture required IBM environment variables and learner prerequisites

### 2.3 Map compute/networking lesson equivalents
- [ ] Confirm IBM equivalents for the cross-cloud networking core:
  - [ ] VPC / virtual network -> `ibm_is_vpc`
  - [ ] subnet -> `ibm_is_subnet`
  - [ ] security rule(s) -> `ibm_is_security_group_rule`
  - [ ] SSH key -> `ibm_is_ssh_key`
  - [ ] virtual machine / instance -> `ibm_is_instance`
  - [ ] public IP / reachable ingress -> `ibm_is_floating_ip`
- [ ] Decide whether public egress parity should also include:
  - [ ] `ibm_is_public_gateway`
  - [ ] `ibm_is_subnet_public_gateway_attachment`
- [ ] Identify image/profile discovery data sources for IBM `202`
- [ ] Verify that the selected IBM resources are beginner-friendly and fit the same complexity level as AWS/Azure/GCP `202`

### 2.4 Map security/storage lesson equivalents
- [ ] Confirm IBM equivalents for storage:
  - [ ] object storage service provisioning -> `ibm_resource_instance`
  - [ ] bucket -> `ibm_cos_bucket`
  - [ ] lifecycle config -> `ibm_cos_bucket_lifecycle_configuration`
  - [ ] website/static hosting config if relevant -> `ibm_cos_bucket_website_configuration`
- [ ] Confirm IBM equivalents for encryption / key management:
  - [ ] KMS instance provisioning -> `ibm_resource_instance`
  - [ ] key -> `ibm_kms_key`
  - [ ] service-to-service authorization -> `ibm_iam_authorization_policy`
- [ ] Evaluate IBM equivalent for secrets management:
  - [ ] `ibm_sm_service_credentials_secret`
  - [ ] related `sm_*` resources/data sources
- [ ] Decide if IBM `203` should include:
  - [ ] only COS + KMS
  - [ ] COS + KMS + Secrets Manager
  - [ ] COS + KMS + IAM access group / policy examples
- [ ] Identify whether block storage parity is needed, and if so, which IBM resource best matches the existing course intent

### 2.5 Map advanced-pattern lesson equivalents
- [ ] Confirm IBM equivalents for templating and scaling:
  - [ ] instance template -> `ibm_is_instance_template`
  - [ ] autoscaling group -> `ibm_is_instance_group`
  - [ ] scaling manager -> `ibm_is_instance_group_manager`
  - [ ] scaling policy -> `ibm_is_instance_group_manager_policy`
  - [ ] scaling actions -> `ibm_is_instance_group_manager_action`
- [ ] Confirm IBM equivalents for load balancing:
  - [ ] load balancer -> `ibm_is_lb`
  - [ ] listener -> `ibm_is_lb_listener`
  - [ ] pool -> `ibm_is_lb_pool`
- [ ] Decide whether to include or exclude:
  - [ ] listener policy resources
  - [ ] advanced LB policy rule resources
  - [ ] managed database resources for parity with GCP advanced module
- [ ] Keep IBM `204` aligned with the **teaching goal** of advanced patterns, not just provider feature abundance

### 2.6 Record IBM gaps and design decisions
- [ ] For each parity item, mark:
  - [ ] direct equivalent exists
  - [ ] partial equivalent exists
  - [ ] no good equivalent found
- [ ] For each partial/no-equivalent case, record:
  - [ ] workaround
  - [ ] teaching simplification
  - [ ] deliberate omission
- [ ] Create an explicit “IBM-specific deviations from AWS/Azure/GCP” section for later documentation

---

## Phase 3 - Decide IBM module structure

### 3.1 Choose module name and numbering
- [ ] Decide final module directory name, for example:
  - [ ] `IBM-200-terraform`
  - [ ] `IC-200-terraform`
  - [ ] `IBM-200-cloud`
- [ ] Decide lesson folder names matching the existing pattern
- [ ] Ensure naming is consistent with the course catalog and root README conventions

### 3.2 Define IBM lesson breakdown
- [ ] Draft the final lesson structure:
  - [ ] `IBM-201-setup-auth`
  - [ ] `IBM-202-compute-networking`
  - [ ] `IBM-203-security-storage`
  - [ ] `IBM-204-advanced-patterns`
- [ ] For each lesson, define:
  - [ ] learning objectives
  - [ ] concepts taught
  - [ ] Terraform resources included
  - [ ] expected outputs/artifacts
  - [ ] expected prerequisites from core training

### 3.3 Define scope boundaries
- [ ] Explicitly list what will **not** be included in v1 of the IBM module
- [ ] Avoid feature creep from broad IBM provider coverage
- [ ] Keep v1 aligned with the pedagogical depth of the current cloud modules

---

## Phase 4 - Create implementation checklist for IBM module files

### 4.1 Create top-level IBM cloud module scaffolding
- [ ] Create IBM module root directory under `cloud-modules/`
- [ ] Add IBM module root `README.md`
- [ ] Add consistent subdirectories for `201`–`204`
- [ ] Update `cloud-modules/README.md` to include IBM
- [ ] Update root `README.md` to include IBM as an optional cloud path

### 4.2 Implement IBM-201 lesson scaffolding
- [ ] Create `README.md`
- [ ] Create `example/main.tf`
- [ ] Create `example/variables.tf`
- [ ] Create `example/outputs.tf` if needed
- [ ] Create `example/tests/basic.tftest.hcl`
- [ ] Add learner instructions:
  - [ ] prerequisites
  - [ ] auth setup
  - [ ] API key handling
  - [ ] region / zone selection
  - [ ] resource group guidance

### 4.3 Implement IBM-202 lesson scaffolding
- [ ] Create `README.md`
- [ ] Create `example/main.tf`
- [ ] Create `example/variables.tf`
- [ ] Create `example/outputs.tf`
- [ ] Create `example/tests/basic.tftest.hcl`
- [ ] Ensure the example covers:
  - [ ] VPC
  - [ ] subnet
  - [ ] security rule(s)
  - [ ] SSH key
  - [ ] instance
  - [ ] floating IP
  - [ ] optionally public gateway attachment if chosen in parity design

### 4.4 Implement IBM-203 lesson scaffolding
- [ ] Create `README.md`
- [ ] Create `example/main.tf`
- [ ] Create `example/variables.tf`
- [ ] Create `example/outputs.tf`
- [ ] Create `example/tests/basic.tftest.hcl`
- [ ] Ensure the example covers final selected scope:
  - [ ] COS instance
  - [ ] COS bucket
  - [ ] lifecycle or website configuration
  - [ ] KMS instance
  - [ ] KMS key
  - [ ] IAM authorization policy
  - [ ] optional Secrets Manager resources if kept in scope

### 4.5 Implement IBM-204 lesson scaffolding
- [ ] Create `README.md`
- [ ] Create `example/main.tf`
- [ ] Create `example/variables.tf`
- [ ] Create `example/outputs.tf`
- [ ] Create `example/tests/basic.tftest.hcl`
- [ ] Ensure the example covers final selected scope:
  - [ ] instance template
  - [ ] instance group
  - [ ] autoscaling manager/policy/action
  - [ ] load balancer
  - [ ] listener
  - [ ] pool
  - [ ] optional database or advanced LB extras only if justified by parity review

---

## Phase 5 - Documentation parity

### 5.1 Match documentation style
- [ ] Compare IBM lesson READMEs against AWS/Azure/GCP README patterns
- [ ] Match tone and structure for:
  - [ ] overview
  - [ ] prerequisites
  - [ ] concepts covered
  - [ ] resource explanation
  - [ ] how to run
  - [ ] cleanup
- [ ] Ensure IBM explanations stay accessible for learners coming from TF-100/200/300 core content

### 5.2 Add IBM-specific guidance where necessary
- [ ] Document IBM authentication clearly:
  - [ ] API key usage
  - [ ] environment variables
  - [ ] region/zone conventions
- [ ] Document IBM-specific service provisioning concepts:
  - [ ] resource groups
  - [ ] `ibm_resource_instance`
  - [ ] service-to-service authorization policies
- [ ] Document cost-awareness and cleanup guidance specific to IBM Cloud

### 5.3 Update course navigation
- [ ] Add IBM path to root course overview
- [ ] Add IBM path to any “choose your path” or catalog docs if needed
- [ ] Ensure repository structure docs reflect the new module

---

## Phase 6 - Testing and validation parity

### 6.1 Test structure parity
- [ ] Compare existing cloud module `.tftest.hcl` files
- [ ] Define the minimum test expectations IBM should match
- [ ] Ensure each IBM lesson has a basic Terraform test mirroring existing style

### 6.2 Validate examples for learner usability
- [ ] Ensure examples can be followed without hidden prerequisites
- [ ] Verify variables are documented and named consistently
- [ ] Ensure outputs are useful for learners
- [ ] Ensure cleanup/destroy instructions are explicit

### 6.3 Validate provider/version alignment
- [ ] Confirm IBM provider version strategy
- [ ] Confirm Terraform version expectations fit the course baseline
- [ ] Ensure no IBM examples rely on unstable/beta-only features unless explicitly documented

---

## Phase 7 - Final review checklist

### 7.1 Content parity review
- [ ] Review IBM module against AWS/Azure/GCP for:
  - [ ] structural parity
  - [ ] lesson parity
  - [ ] artifact parity
  - [ ] testing parity
  - [ ] documentation parity

### 7.2 Pedagogical review
- [ ] Confirm IBM lessons teach the same class of concepts, not just different IBM products
- [ ] Confirm complexity is appropriate for learners finishing the core modules
- [ ] Remove IBM-specific noise that does not improve learning outcomes

### 7.3 Repository review
- [ ] Verify links and paths
- [ ] Verify README references
- [ ] Verify course catalog references
- [ ] Verify naming consistency across all new files/directories

---

## IBM candidate resource mapping snapshot

This is the current candidate mapping baseline to validate while implementing:

### IBM-201 Setup / Auth
- Candidate focus:
  - provider `ibm`
  - authentication via IBM Cloud API key
  - region / zone / resource group setup
  - account/resource group data sources as needed

### IBM-202 Compute / Networking
- `ibm_is_vpc`
- `ibm_is_subnet`
- `ibm_is_security_group_rule`
- `ibm_is_ssh_key`
- `ibm_is_instance`
- `ibm_is_floating_ip`
- optional:
  - `ibm_is_public_gateway`
  - `ibm_is_subnet_public_gateway_attachment`

### IBM-203 Security / Storage
- `ibm_resource_instance`
- `ibm_cos_bucket`
- `ibm_cos_bucket_lifecycle_configuration`
- `ibm_cos_bucket_website_configuration` (if useful)
- `ibm_kms_key`
- `ibm_iam_authorization_policy`
- optional:
  - `ibm_sm_service_credentials_secret`
  - additional `sm_*` secrets resources/data sources

### IBM-204 Advanced Patterns
- `ibm_is_instance_template`
- `ibm_is_instance_group`
- `ibm_is_instance_group_manager`
- `ibm_is_instance_group_manager_policy`
- `ibm_is_instance_group_manager_action`
- `ibm_is_lb`
- `ibm_is_lb_listener`
- `ibm_is_lb_pool`

---

## Deliverables expected at the end of this work

- [ ] New IBM cloud module directory under `cloud-modules/`
- [ ] Four IBM lesson units with examples and tests
- [ ] Updated root/course documentation to advertise IBM as a supported path
- [ ] Clear parity notes describing where IBM intentionally differs from AWS/Azure/GCP
- [ ] Learner-ready documentation matching the style of existing cloud modules