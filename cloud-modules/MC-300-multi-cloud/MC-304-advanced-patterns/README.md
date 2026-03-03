# MC-304: Advanced Multi-Cloud Patterns

**Course**: MC-300 Multi-Cloud Architecture  
**Module**: MC-304  
**Duration**: 1 hour  
**Prerequisites**: MC-303 (Cross-Cloud Networking)  
**Difficulty**: Advanced

---

## 📋 Table of Contents

1. [Course Overview](#course-overview)
2. [Learning Objectives](#learning-objectives)
3. [GitOps for Multi-Cloud](#gitops-for-multi-cloud)
4. [Multi-Cloud Observability](#multi-cloud-observability)
5. [Secrets Management Across Clouds](#secrets-management-across-clouds)
6. [Multi-Cloud CI/CD Pipelines](#multi-cloud-cicd-pipelines)
7. [Disaster Recovery Patterns](#disaster-recovery-patterns)
8. [Cost Optimization](#cost-optimization)
9. [Best Practices Summary](#best-practices-summary)
10. [Hands-On Labs](#hands-on-labs)
11. [Checkpoint Quiz](#checkpoint-quiz)
12. [Additional Resources](#additional-resources)

---

## 🎯 Course Overview

This capstone course covers advanced operational patterns for running production multi-cloud infrastructure. You'll learn GitOps workflows, unified observability, cross-cloud secrets management, CI/CD pipelines, and disaster recovery strategies that work across AWS and Azure.

### What You'll Learn

By the end of this course, you'll be able to:
- Implement GitOps workflows for multi-cloud Terraform
- Build unified observability across clouds
- Manage secrets consistently across AWS and Azure
- Design CI/CD pipelines for multi-cloud deployments
- Implement disaster recovery across cloud providers
- Optimize costs in a multi-cloud environment

### Course Structure

```
MC-304-advanced-patterns/
├── README.md                          # This file
└── example/
    ├── main.tf                        # Main configuration
    ├── observability.tf               # Monitoring setup
    ├── secrets.tf                     # Cross-cloud secrets
    ├── dr.tf                          # Disaster recovery
    ├── variables.tf                   # Input variables
    ├── outputs.tf                     # Output values
    └── versions.tf                    # Version constraints
```

---

## 🎓 Learning Objectives

After completing this course, you will be able to:

1. **Implement GitOps**
   - Structure repositories for multi-cloud
   - Use Terraform Cloud/HCP for remote execution
   - Implement pull request workflows

2. **Build Observability**
   - Aggregate logs from multiple clouds
   - Create unified dashboards
   - Set up cross-cloud alerting

3. **Manage Secrets**
   - Use HashiCorp Vault for cross-cloud secrets
   - Implement secret rotation
   - Audit secret access

4. **Design CI/CD**
   - Build multi-cloud deployment pipelines
   - Implement progressive delivery
   - Automate testing across clouds

5. **Plan Disaster Recovery**
   - Define RTO/RPO for multi-cloud
   - Implement automated failover
   - Test DR procedures

---

## 🔄 GitOps for Multi-Cloud

### Repository Structure

```
infrastructure/
├── .github/
│   └── workflows/
│       ├── terraform-plan.yml         # PR: plan only
│       └── terraform-apply.yml        # Main: plan + apply
├── modules/
│   ├── cloud-vm/                      # Shared modules
│   ├── cloud-network/
│   └── cloud-storage/
├── environments/
│   ├── dev/
│   │   ├── aws/
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   └── backend.tf
│   │   └── azure/
│   │       ├── main.tf
│   │       ├── variables.tf
│   │       └── backend.tf
│   ├── staging/
│   │   ├── aws/
│   │   └── azure/
│   └── prod/
│       ├── aws/
│       └── azure/
└── README.md
```

### GitHub Actions Workflow

```yaml
# .github/workflows/terraform-plan.yml
name: Terraform Plan

on:
  pull_request:
    paths:
      - 'environments/**'
      - 'modules/**'

jobs:
  plan-aws:
    name: Plan AWS
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
      
      - uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: "~1.9"
      
      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
          aws-region: us-east-1
      
      - name: Terraform Init
        run: terraform init
        working-directory: environments/${{ github.event.inputs.environment }}/aws
      
      - name: Terraform Plan
        run: terraform plan -out=tfplan
        working-directory: environments/${{ github.event.inputs.environment }}/aws
      
      - name: Comment Plan on PR
        uses: actions/github-script@v7
        with:
          script: |
            const plan = require('fs').readFileSync('tfplan.txt', 'utf8');
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: `## AWS Terraform Plan\n\`\`\`\n${plan}\n\`\`\``
            });

  plan-azure:
    name: Plan Azure
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
      
      - uses: hashicorp/setup-terraform@v3
      
      - name: Azure Login
        uses: azure/login@v2
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
      
      - name: Terraform Init & Plan
        run: |
          terraform init
          terraform plan -out=tfplan
        working-directory: environments/${{ github.event.inputs.environment }}/azure
        env:
          ARM_USE_OIDC: true
          ARM_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
          ARM_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}
          ARM_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
```

### Terraform Cloud Workspaces

```hcl
# Using HCP Terraform for remote execution
terraform {
  cloud {
    organization = "my-org"
    
    workspaces {
      name = "prod-aws-networking"
    }
  }
}
```

---

## 📊 Multi-Cloud Observability

### Centralized Logging Architecture

```
AWS CloudWatch Logs ──────┐
                          ├──→ Log Aggregator (e.g., Datadog/Grafana)
Azure Monitor Logs ───────┘         │
                                    ▼
                            Unified Dashboard
                            Unified Alerting
```

### AWS CloudWatch to External

```hcl
# observability.tf

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "app" {
  name              = "/app/${var.project_name}"
  retention_in_days = 30
  
  tags = local.common_tags
}

# CloudWatch Metric Alarm
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.project_name}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "CPU utilization > 80%"
  
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web.name
  }
  
  alarm_actions = [aws_sns_topic.alerts.arn]
}

# SNS Topic for alerts
resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}
```

### Azure Monitor

```hcl
# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "main" {
  name                = "${var.project_name}-law"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  
  tags = local.common_tags
}

# Diagnostic settings for VM
resource "azurerm_monitor_diagnostic_setting" "vm" {
  name               = "${var.project_name}-vm-diag"
  target_resource_id = azurerm_linux_virtual_machine.web.id
  
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  
  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

# Azure Monitor Alert
resource "azurerm_monitor_metric_alert" "high_cpu" {
  name                = "${var.project_name}-high-cpu"
  resource_group_name = azurerm_resource_group.main.name
  scopes              = [azurerm_linux_virtual_machine_scale_set.web.id]
  description         = "CPU utilization > 80%"
  
  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachineScaleSets"
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }
  
  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }
}

resource "azurerm_monitor_action_group" "main" {
  name                = "${var.project_name}-ag"
  resource_group_name = azurerm_resource_group.main.name
  short_name          = "alerts"
  
  email_receiver {
    name          = "admin"
    email_address = var.alert_email
  }
}
```

---

## 🔑 Secrets Management Across Clouds

### HashiCorp Vault (Cloud-Agnostic)

```hcl
# secrets.tf

# Vault provider (works with any cloud)
provider "vault" {
  address = var.vault_address
  token   = var.vault_token  # Or use auth method
}

# Store AWS credentials in Vault
resource "vault_generic_secret" "aws_creds" {
  path = "secret/multi-cloud/aws"
  
  data_json = jsonencode({
    access_key = var.aws_access_key
    secret_key = var.aws_secret_key
  })
}

# Store Azure credentials in Vault
resource "vault_generic_secret" "azure_creds" {
  path = "secret/multi-cloud/azure"
  
  data_json = jsonencode({
    client_id     = var.azure_client_id
    client_secret = var.azure_client_secret
    tenant_id     = var.azure_tenant_id
  })
}

# Read secrets from Vault
data "vault_generic_secret" "db_password" {
  path = "secret/multi-cloud/database"
}

# Use in AWS RDS
resource "aws_db_instance" "main" {
  password = data.vault_generic_secret.db_password.data["password"]
  # ...
}

# Use in Azure SQL
resource "azurerm_mssql_server" "main" {
  administrator_login_password = data.vault_generic_secret.db_password.data["password"]
  # ...
}
```

### Cross-Cloud Secret Sync Pattern

```hcl
# Read from AWS Secrets Manager
data "aws_secretsmanager_secret_version" "shared" {
  secret_id = "shared/database-credentials"
}

# Write to Azure Key Vault (sync pattern)
resource "azurerm_key_vault_secret" "db_password" {
  name         = "database-password"
  value        = jsondecode(data.aws_secretsmanager_secret_version.shared.secret_string)["password"]
  key_vault_id = azurerm_key_vault.main.id
}
```

---

## 🚀 Multi-Cloud CI/CD Pipelines

### Pipeline Architecture

```
Git Push → CI Pipeline
              │
              ├── Lint & Validate (both clouds)
              ├── Security Scan (tfsec, checkov)
              ├── Plan AWS
              ├── Plan Azure
              │
              └── On Approval:
                  ├── Apply AWS (dev → staging → prod)
                  └── Apply Azure (dev → staging → prod)
```

### Terraform Validation Pipeline

```hcl
# In CI: validate both cloud configurations

# .github/workflows/validate.yml
# steps:
#   - terraform fmt -check -recursive
#   - terraform validate (aws/)
#   - terraform validate (azure/)
#   - tfsec . (security scan)
#   - checkov -d . (compliance scan)
```

### Progressive Deployment

```hcl
# Deploy to dev first, then staging, then prod
# Use Terraform workspaces or separate directories

locals {
  deployment_order = ["dev", "staging", "prod"]
  
  # Canary: deploy to 10% of prod first
  canary_weight = var.environment == "prod" ? 10 : 100
}
```

---

## 🔄 Disaster Recovery Patterns

### RTO and RPO Definitions

```
RTO (Recovery Time Objective):  How long can you be down?
RPO (Recovery Point Objective): How much data can you lose?

Multi-cloud DR tiers:
├── Tier 1 (Mission Critical): RTO < 1h,  RPO < 15min  → Active-Active
├── Tier 2 (Business Critical): RTO < 4h,  RPO < 1h    → Active-Passive (warm)
└── Tier 3 (Standard):          RTO < 24h, RPO < 4h    → Backup & Restore
```

### Active-Passive DR Configuration

```hcl
# dr.tf

# Primary: AWS (active)
resource "aws_instance" "primary" {
  # Full production configuration
  instance_type = "t3.medium"
  # ...
}

# Secondary: Azure (passive/warm standby)
resource "azurerm_linux_virtual_machine" "standby" {
  # Reduced capacity standby
  size = "Standard_B2s"
  # ...
  
  # Tag as standby
  tags = merge(local.common_tags, {
    Role = "standby"
    DR   = "true"
  })
}

# Route53 health check for failover
resource "aws_route53_health_check" "primary" {
  fqdn              = aws_instance.primary.public_dns
  port              = 443
  type              = "HTTPS"
  resource_path     = "/health"
  failure_threshold = 3
  request_interval  = 30
}

# DNS failover record
resource "aws_route53_record" "app" {
  zone_id = aws_route53_zone.public.zone_id
  name    = "app.${var.domain_name}"
  type    = "A"
  
  failover_routing_policy {
    type = "PRIMARY"
  }
  
  set_identifier  = "primary"
  health_check_id = aws_route53_health_check.primary.id
  ttl             = 60
  records         = [aws_instance.primary.public_ip]
}

resource "aws_route53_record" "app_failover" {
  zone_id = aws_route53_zone.public.zone_id
  name    = "app.${var.domain_name}"
  type    = "A"
  
  failover_routing_policy {
    type = "SECONDARY"
  }
  
  set_identifier = "secondary"
  ttl            = 60
  records        = [azurerm_public_ip.standby.ip_address]
}
```

### Database Replication for DR

```hcl
# AWS RDS with cross-region read replica
resource "aws_db_instance" "primary" {
  identifier     = "${var.project_name}-primary"
  engine         = "postgres"
  engine_version = "15.4"
  instance_class = "db.t3.medium"
  # ...
  
  backup_retention_period = 7
  backup_window           = "03:00-04:00"
}

# Azure Database as DR target
resource "azurerm_postgresql_flexible_server" "dr" {
  name                = "${var.project_name}-dr-db"
  resource_group_name = azurerm_resource_group.dr.name
  location            = var.dr_region
  
  # Restore from backup for DR testing
  # create_mode      = "PointInTimeRestore"
  # source_server_id = "..."
  # restore_point_in_time = "..."
  
  sku_name   = "B_Standard_B1ms"
  storage_mb = 32768
  version    = "15"
  
  administrator_login    = var.db_admin_username
  administrator_password = var.db_admin_password
}
```

---

## 💰 Cost Optimization

### Cost Allocation Tags

```hcl
locals {
  cost_tags = {
    CostCenter  = var.cost_center
    Project     = var.project_name
    Environment = var.environment
    Team        = var.team_name
    Cloud       = "multi-cloud"
  }
}
```

### Right-Sizing Strategy

```hcl
variable "environment_sizing" {
  description = "Resource sizing per environment"
  type = map(object({
    aws_instance_type = string
    azure_vm_size     = string
    min_instances     = number
    max_instances     = number
  }))
  
  default = {
    dev = {
      aws_instance_type = "t3.micro"
      azure_vm_size     = "Standard_B1s"
      min_instances     = 1
      max_instances     = 2
    }
    staging = {
      aws_instance_type = "t3.small"
      azure_vm_size     = "Standard_B2s"
      min_instances     = 1
      max_instances     = 4
    }
    prod = {
      aws_instance_type = "t3.medium"
      azure_vm_size     = "Standard_D2s_v3"
      min_instances     = 2
      max_instances     = 10
    }
  }
}
```

### Scheduled Shutdown for Non-Prod

```hcl
# AWS: Stop instances outside business hours
resource "aws_autoscaling_schedule" "scale_down_night" {
  count = var.environment != "prod" ? 1 : 0
  
  scheduled_action_name  = "scale-down-night"
  min_size               = 0
  max_size               = 0
  desired_capacity       = 0
  recurrence             = "0 18 * * MON-FRI"  # 6 PM weekdays
  autoscaling_group_name = aws_autoscaling_group.web.name
}

resource "aws_autoscaling_schedule" "scale_up_morning" {
  count = var.environment != "prod" ? 1 : 0
  
  scheduled_action_name  = "scale-up-morning"
  min_size               = 1
  max_size               = 4
  desired_capacity       = 2
  recurrence             = "0 8 * * MON-FRI"  # 8 AM weekdays
  autoscaling_group_name = aws_autoscaling_group.web.name
}
```

---

## ✅ Best Practices Summary

### Multi-Cloud Terraform Checklist

```
Infrastructure Design:
✅ Non-overlapping CIDR blocks planned
✅ Consistent naming conventions across clouds
✅ Required tags defined and enforced
✅ Cost center allocation implemented

Security:
✅ No hardcoded credentials
✅ Least-privilege IAM/RBAC
✅ Secrets in Vault/KMS/Key Vault
✅ Network security groups configured
✅ Encryption at rest and in transit

Operations:
✅ Remote state with locking
✅ State per cloud/environment
✅ GitOps workflow implemented
✅ CI/CD pipeline with plan review
✅ Monitoring and alerting configured

Reliability:
✅ Multi-AZ/zone deployments
✅ Auto-scaling configured
✅ Health checks implemented
✅ DR plan documented and tested
✅ RTO/RPO defined per workload
```

---

## 🔬 Hands-On Labs

### Lab 1: GitOps Repository Structure (15 minutes)

**Objective**: Set up a GitOps-ready repository structure for multi-cloud.

**Tasks**:
1. Create directory structure (environments/dev/aws, environments/dev/azure)
2. Create GitHub Actions workflow for plan on PR
3. Create workflow for apply on merge to main
4. Configure OIDC authentication for both clouds
5. Test PR workflow with a small change
6. Verify plan comments appear on PR

**Expected Output**:
- Repository with GitOps structure
- Automated plan on PR
- Automated apply on merge

---

### Lab 2: Unified Alerting (15 minutes)

**Objective**: Configure alerts in both clouds that notify the same endpoint.

**Tasks**:
1. Create SNS topic in AWS for alerts
2. Create Action Group in Azure for alerts
3. Configure CPU alerts in both clouds
4. Point both to the same email/webhook
5. Trigger a test alert in each cloud
6. Verify notifications received

**Expected Output**:
- CPU alerts configured in AWS and Azure
- Both alert to same destination
- Test alerts received

---

### Lab 3: DR Failover Test (20 minutes)

**Objective**: Test DNS-based failover from AWS to Azure.

**Tasks**:
1. Deploy primary app in AWS with health check
2. Deploy standby app in Azure
3. Configure Route53 failover routing
4. Simulate primary failure (stop AWS instance)
5. Verify DNS fails over to Azure
6. Restore primary and verify failback

**Expected Output**:
- DNS failover working
- Traffic routes to Azure when AWS is down
- Failback works when AWS recovers

---

## 📝 Checkpoint Quiz

### Question 1: GitOps Principle
**What is the core principle of GitOps for infrastructure?**

A) Using Git for application code only  
B) Git repository is the single source of truth; changes applied via automated pipelines  
C) Manual deployments tracked in Git  
D) Git replaces Terraform

<details>
<summary>Click to reveal answer</summary>

**Answer: B) Git repository is the single source of truth; changes applied via automated pipelines**

GitOps means all infrastructure changes are made through Git (pull requests), and automated pipelines apply those changes. No manual `terraform apply` in production - everything goes through the pipeline.
</details>

---

### Question 2: RTO vs RPO
**A system has RTO = 4 hours and RPO = 1 hour. What does this mean?**

A) The system can be down for 1 hour and lose 4 hours of data  
B) The system can be down for 4 hours and lose up to 1 hour of data  
C) Recovery takes 4 hours and 1 hour of setup  
D) Both values must be equal

<details>
<summary>Click to reveal answer</summary>

**Answer: B) The system can be down for 4 hours and lose up to 1 hour of data**

RTO (Recovery Time Objective) = maximum acceptable downtime = 4 hours. RPO (Recovery Point Objective) = maximum acceptable data loss = 1 hour. Backups must run at least every hour to meet the RPO.
</details>

---

### Question 3: HashiCorp Vault Benefit
**Why use HashiCorp Vault for multi-cloud secrets instead of AWS Secrets Manager or Azure Key Vault alone?**

A) Vault is cheaper  
B) Vault provides a single, cloud-agnostic secrets API for all clouds  
C) Vault has better encryption  
D) Required for Terraform

<details>
<summary>Click to reveal answer</summary>

**Answer: B) Vault provides a single, cloud-agnostic secrets API for all clouds**

Vault works identically regardless of which cloud you're on. Applications use the same Vault API whether running on AWS or Azure, avoiding cloud-specific secret management code and enabling true portability.
</details>

---

### Question 4: OIDC Authentication
**Why is OIDC preferred over long-lived credentials for CI/CD pipelines?**

A) OIDC is faster  
B) OIDC tokens are short-lived and don't require storing credentials as secrets  
C) OIDC provides more permissions  
D) Required by GitHub Actions

<details>
<summary>Click to reveal answer</summary>

**Answer: B) OIDC tokens are short-lived and don't require storing credentials as secrets**

OIDC (OpenID Connect) allows CI/CD systems to exchange a short-lived token for cloud credentials without storing long-lived access keys. This eliminates the risk of credential leakage from secret stores.
</details>

---

### Question 5: Cost Optimization
**What is the most effective cost optimization for non-production multi-cloud environments?**

A) Use smaller instance types  
B) Schedule automatic shutdown outside business hours  
C) Delete and recreate environments daily  
D) Use spot/preemptible instances only

<details>
<summary>Click to reveal answer</summary>

**Answer: B) Schedule automatic shutdown outside business hours**

Scheduling dev/staging environments to shut down at night and weekends (when not in use) can reduce costs by 60-70%. This is the highest-impact, lowest-risk optimization for non-production environments.
</details>

---

### Question 6: Multi-Cloud Maturity
**What is the correct order of multi-cloud adoption maturity?**

A) Active-Active → Active-Passive → Single Cloud  
B) Single Cloud → Active-Passive DR → Workload Distribution → Active-Active  
C) Active-Active → Workload Distribution → Single Cloud  
D) All patterns should be implemented simultaneously

<details>
<summary>Click to reveal answer</summary>

**Answer: B) Single Cloud → Active-Passive DR → Workload Distribution → Active-Active**

Start with mastering one cloud, then add DR capability to a second cloud, then distribute workloads based on best-of-breed services, and finally implement active-active only if the business case justifies the complexity and cost.
</details>

---

## 🎓 Course Completion

Congratulations on completing **MC-300: Multi-Cloud Architecture**!

### What You've Mastered

- ✅ **MC-301**: Multi-cloud strategy, patterns, and Terraform setup
- ✅ **MC-302**: Provider abstraction and cloud-agnostic modules
- ✅ **MC-303**: Cross-cloud networking with VPN and DNS
- ✅ **MC-304**: Advanced patterns: GitOps, observability, DR, cost optimization

### Your Multi-Cloud Toolkit

```
Design:      Multi-cloud patterns, IP planning, abstraction layers
Code:        Provider aliases, conditional resources, normalized outputs
Networking:  VPN gateways, BGP routing, cross-cloud DNS
Operations:  GitOps, CI/CD, unified monitoring, secrets management
Reliability: DR patterns, RTO/RPO, automated failover
Cost:        Tagging, right-sizing, scheduled shutdown
```

### Next Steps

- Apply these patterns to a real project
- Explore Terraform Cloud for team collaboration
- Consider HashiCorp Vault for enterprise secrets management
- Study cloud-specific certifications (AWS SAA, Azure Administrator)

---

## 📚 Additional Resources

### Official Documentation
- [Terraform Multi-Cloud](https://developer.hashicorp.com/terraform/tutorials/multi-cloud)
- [HashiCorp Vault](https://developer.hashicorp.com/vault)
- [GitHub Actions OIDC](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect)
- [AWS DR Whitepaper](https://docs.aws.amazon.com/whitepapers/latest/disaster-recovery-workloads-on-aws/disaster-recovery-workloads-on-aws.html)

### Complete Training Path
- **[TF-100](../../../TF-100-fundamentals/README.md)**: Terraform Fundamentals
- **[TF-200](../../../TF-200-modules/README.md)**: Modules & Patterns
- **[TF-300](../../../TF-300-advanced/README.md)**: Testing & Policy
- **[PKR-100](../../../PKR-100-fundamentals/README.md)**: Packer Fundamentals
- **[AWS-200](../../AWS-200-terraform/README.md)**: AWS with Terraform
- **[AZ-200](../../AZ-200-terraform/README.md)**: Azure with Terraform
- **[MC-300](../README.md)**: Multi-Cloud Architecture ← You are here

---

*Part of the [Hashi-Training](../../../README.md) curriculum - MC-300: Multi-Cloud Architecture*