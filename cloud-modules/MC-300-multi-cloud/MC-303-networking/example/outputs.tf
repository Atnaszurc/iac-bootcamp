# MC-303: Cross-Cloud Networking - Outputs

# ---------------------------------------------------------------------------
# IP address planning summary
# ---------------------------------------------------------------------------

output "ip_allocation" {
  description = "IP address allocation across both clouds (must be non-overlapping)"
  value = {
    aws_vpc_cidr              = var.aws_vpc_cidr
    aws_private_subnet_a_cidr = var.aws_private_subnet_a_cidr
    aws_private_subnet_b_cidr = var.aws_private_subnet_b_cidr
    azure_vnet_cidr           = var.azure_vnet_cidr
    azure_app_subnet_cidr     = var.azure_app_subnet_cidr
    azure_gateway_subnet_cidr = var.azure_gateway_subnet_cidr
  }
}

# ---------------------------------------------------------------------------
# AWS outputs
# ---------------------------------------------------------------------------

output "aws_vpc_id" {
  description = "AWS VPC ID"
  value       = aws_vpc.main.id
}

output "aws_vpn_gateway_id" {
  description = "AWS VPN Gateway ID"
  value       = aws_vpn_gateway.main.id
}

output "aws_customer_gateway_id" {
  description = "AWS Customer Gateway ID (represents Azure endpoint)"
  value       = aws_customer_gateway.azure.id
}

output "aws_vpn_connection_id" {
  description = "AWS VPN Connection ID"
  value       = aws_vpn_connection.to_azure.id
}

output "aws_vpn_tunnel1_address" {
  description = "AWS VPN tunnel 1 public IP (needed for Azure Local Network Gateway)"
  value       = aws_vpn_connection.to_azure.tunnel1_address
}

output "aws_vpn_tunnel2_address" {
  description = "AWS VPN tunnel 2 public IP (for redundancy)"
  value       = aws_vpn_connection.to_azure.tunnel2_address
}

output "aws_route53_zone_id" {
  description = "Route53 private hosted zone ID for aws.internal"
  value       = aws_route53_zone.private.zone_id
}

output "aws_route53_zone_name" {
  description = "Route53 private hosted zone name"
  value       = aws_route53_zone.private.name
}

# ---------------------------------------------------------------------------
# Azure outputs
# ---------------------------------------------------------------------------

output "azure_resource_group_name" {
  description = "Azure resource group name"
  value       = azurerm_resource_group.main.name
}

output "azure_vnet_id" {
  description = "Azure Virtual Network ID"
  value       = azurerm_virtual_network.main.id
}

output "azure_vpn_gateway_id" {
  description = "Azure VPN Gateway resource ID"
  value       = azurerm_virtual_network_gateway.main.id
}

output "azure_vpn_public_ip" {
  description = "Azure VPN Gateway public IP address (needed for AWS Customer Gateway)"
  value       = azurerm_public_ip.vpn_gw.ip_address
}

output "azure_gateway_subnet_id" {
  description = "Azure GatewaySubnet ID"
  value       = azurerm_subnet.gateway.id
}

output "azure_private_dns_zone_id" {
  description = "Azure Private DNS Zone ID for azure.internal"
  value       = azurerm_private_dns_zone.main.id
}

output "azure_private_dns_zone_name" {
  description = "Azure Private DNS Zone name"
  value       = azurerm_private_dns_zone.main.name
}

# ---------------------------------------------------------------------------
# Cross-cloud connectivity summary
# ---------------------------------------------------------------------------

output "vpn_connectivity" {
  description = "VPN connectivity configuration summary"
  value = {
    aws_to_azure = {
      vpn_connection_id   = aws_vpn_connection.to_azure.id
      customer_gateway_ip = aws_customer_gateway.azure.ip_address
      bgp_enabled         = true
      aws_bgp_asn         = var.aws_bgp_asn
    }
    azure_to_aws = {
      gateway_id      = azurerm_virtual_network_gateway.main.id
      connection_id   = azurerm_virtual_network_gateway_connection.to_aws.id
      azure_bgp_asn   = var.azure_bgp_asn
    }
  }
}

output "dns_zones" {
  description = "Private DNS zones for cross-cloud resolution"
  value = {
    aws_zone   = aws_route53_zone.private.name
    azure_zone = azurerm_private_dns_zone.main.name
  }
}