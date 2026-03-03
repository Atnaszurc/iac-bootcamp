# MC-303: Cross-Cloud Networking
# Variables for VPN gateway and DNS configuration example

variable "project_name" {
  description = "Project name used across all cloud resources"
  type        = string
  default     = "mc303-demo"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must be lowercase alphanumeric with hyphens only."
  }
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be 'dev', 'staging', or 'prod'."
  }
}

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "azure_region" {
  description = "Azure region for resources"
  type        = string
  default     = "West Europe"
}

variable "azure_subscription_id" {
  description = "Azure subscription ID"
  type        = string
  default     = "00000000-0000-0000-0000-000000000000"
}

# ---------------------------------------------------------------------------
# IP address planning (non-overlapping CIDRs - critical for cross-cloud VPN)
# ---------------------------------------------------------------------------

variable "aws_vpc_cidr" {
  description = "CIDR block for AWS VPC (must not overlap with Azure VNet)"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.aws_vpc_cidr, 0))
    error_message = "AWS VPC CIDR must be a valid CIDR block."
  }
}

variable "azure_vnet_cidr" {
  description = "CIDR block for Azure VNet (must not overlap with AWS VPC)"
  type        = string
  default     = "10.1.0.0/16"

  validation {
    condition     = can(cidrhost(var.azure_vnet_cidr, 0))
    error_message = "Azure VNet CIDR must be a valid CIDR block."
  }
}

variable "aws_private_subnet_a_cidr" {
  description = "CIDR for AWS private subnet in AZ-a"
  type        = string
  default     = "10.0.1.0/24"
}

variable "aws_private_subnet_b_cidr" {
  description = "CIDR for AWS private subnet in AZ-b"
  type        = string
  default     = "10.0.2.0/24"
}

variable "azure_app_subnet_cidr" {
  description = "CIDR for Azure application subnet"
  type        = string
  default     = "10.1.1.0/24"
}

variable "azure_gateway_subnet_cidr" {
  description = "CIDR for Azure GatewaySubnet (required for VPN gateway)"
  type        = string
  default     = "10.1.255.0/27"
}

variable "azure_dns_inbound_subnet_cidr" {
  description = "CIDR for Azure DNS resolver inbound endpoint subnet"
  type        = string
  default     = "10.1.2.0/28"
}

variable "azure_dns_outbound_subnet_cidr" {
  description = "CIDR for Azure DNS resolver outbound endpoint subnet"
  type        = string
  default     = "10.1.3.0/28"
}

# ---------------------------------------------------------------------------
# BGP ASN configuration
# ---------------------------------------------------------------------------

variable "aws_bgp_asn" {
  description = "BGP ASN for AWS side of VPN"
  type        = number
  default     = 64512
}

variable "azure_bgp_asn" {
  description = "BGP ASN for Azure VPN gateway"
  type        = number
  default     = 65515
}