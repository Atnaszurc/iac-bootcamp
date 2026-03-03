# MC-303: Cross-Cloud Networking - Tests
# Uses mock_provider for both AWS and Azure (no credentials required)
# Key tests: non-overlapping CIDRs, VPN gateway config, DNS zones, security rules
# Requires Terraform >= 1.7.0

mock_provider "aws" {
  mock_resource "aws_vpn_connection" {
    defaults = {
      id                      = "vpn-0abc123def456789"
      tunnel1_address         = "203.0.113.10"
      tunnel2_address         = "203.0.113.11"
      tunnel1_preshared_key   = "mock-preshared-key-1"
      tunnel2_preshared_key   = "mock-preshared-key-2"
      tunnel1_cgw_inside_address = "169.254.21.2"
      tunnel1_vgw_inside_address = "169.254.21.1"
    }
  }
}

mock_provider "azurerm" {
  mock_resource "azurerm_virtual_network" {
    defaults = {
      id = "/subscriptions/12345678-1234-9876-4563-123456789012/resourceGroups/test-rg/providers/Microsoft.Network/virtualNetworks/test-vnet"
    }
  }
  
  mock_resource "azurerm_subnet" {
    defaults = {
      id = "/subscriptions/12345678-1234-9876-4563-123456789012/resourceGroups/test-rg/providers/Microsoft.Network/virtualNetworks/test-vnet/subnets/GatewaySubnet"
    }
  }
  
  mock_resource "azurerm_public_ip" {
    defaults = {
      id = "/subscriptions/12345678-1234-9876-4563-123456789012/resourceGroups/test-rg/providers/Microsoft.Network/publicIPAddresses/test-pip"
    }
  }
  
  mock_resource "azurerm_virtual_network_gateway" {
    defaults = {
      id = "/subscriptions/12345678-1234-9876-4563-123456789012/resourceGroups/test-rg/providers/Microsoft.Network/virtualNetworkGateways/test-vng"
    }
  }
  
  mock_resource "azurerm_local_network_gateway" {
    defaults = {
      id = "/subscriptions/12345678-1234-9876-4563-123456789012/resourceGroups/test-rg/providers/Microsoft.Network/localNetworkGateways/test-lng"
    }
  }
}

# ---------------------------------------------------------------------------
# Run 1: Non-overlapping CIDR blocks (critical for VPN routing)
# ---------------------------------------------------------------------------

run "non_overlapping_cidrs" {
  command = plan

  assert {
    condition     = var.aws_vpc_cidr == "10.0.0.0/16"
    error_message = "AWS VPC CIDR should be 10.0.0.0/16."
  }

  assert {
    condition     = var.azure_vnet_cidr == "10.1.0.0/16"
    error_message = "Azure VNet CIDR should be 10.1.0.0/16."
  }

  assert {
    condition     = var.aws_vpc_cidr != var.azure_vnet_cidr
    error_message = "AWS and Azure CIDRs must not overlap."
  }

  assert {
    condition     = aws_vpc.main.cidr_block == "10.0.0.0/16"
    error_message = "AWS VPC should use the configured CIDR."
  }

  assert {
    condition     = tolist(azurerm_virtual_network.main.address_space)[0] == "10.1.0.0/16"
    error_message = "Azure VNet should use the configured CIDR."
  }
}

# ---------------------------------------------------------------------------
# Run 2: AWS VPN gateway configuration
# ---------------------------------------------------------------------------

run "aws_vpn_gateway_config" {
  command = apply

  assert {
    condition     = aws_vpn_gateway.main.vpc_id == aws_vpc.main.id
    error_message = "AWS VPN gateway must be attached to the VPC."
  }

  assert {
    condition     = tonumber(aws_customer_gateway.azure.bgp_asn) == 65515
    error_message = "Customer gateway BGP ASN should match Azure default (65515)."
  }

  assert {
    condition     = aws_customer_gateway.azure.type == "ipsec.1"
    error_message = "Customer gateway type must be ipsec.1."
  }

  assert {
    condition     = aws_vpn_connection.to_azure.static_routes_only == false
    error_message = "VPN connection should use BGP (static_routes_only = false)."
  }
}

# ---------------------------------------------------------------------------
# Run 3: Azure VPN gateway configuration
# ---------------------------------------------------------------------------

run "azure_vpn_gateway_config" {
  command = plan

  assert {
    condition     = azurerm_virtual_network_gateway.main.type == "Vpn"
    error_message = "Azure gateway type must be 'Vpn'."
  }

  assert {
    condition     = azurerm_virtual_network_gateway.main.vpn_type == "RouteBased"
    error_message = "Azure VPN type must be 'RouteBased'."
  }

  assert {
    condition     = azurerm_virtual_network_gateway.main.enable_bgp == true
    error_message = "Azure VPN gateway must have BGP enabled."
  }

  assert {
    condition     = azurerm_virtual_network_gateway.main.bgp_settings[0].asn == 65515
    error_message = "Azure VPN gateway BGP ASN should be 65515."
  }
}

# ---------------------------------------------------------------------------
# Run 4: GatewaySubnet has the required exact name
# ---------------------------------------------------------------------------

run "gateway_subnet_name" {
  command = plan

  assert {
    condition     = azurerm_subnet.gateway.name == "GatewaySubnet"
    error_message = "Azure gateway subnet must be named exactly 'GatewaySubnet'."
  }

  assert {
    condition     = azurerm_subnet.gateway.address_prefixes[0] == "10.1.255.0/27"
    error_message = "Gateway subnet CIDR should be 10.1.255.0/27."
  }
}

# ---------------------------------------------------------------------------
# Run 5: Cross-cloud security rules allow correct traffic
# ---------------------------------------------------------------------------

run "cross_cloud_security_rules" {
  command = plan

  # AWS security group allows HTTPS from Azure VNet
  assert {
    condition = anytrue([
      for rule in aws_security_group.cross_cloud.ingress :
      rule.from_port == 443 && contains(rule.cidr_blocks, "10.1.0.0/16")
    ])
    error_message = "AWS security group must allow HTTPS (443) from Azure VNet CIDR."
  }

  # Azure NSG allows HTTPS from AWS VPC
  assert {
    condition = anytrue([
      for rule in azurerm_network_security_group.cross_cloud.security_rule :
      rule.destination_port_range == "443" && rule.source_address_prefix == "10.0.0.0/16"
    ])
    error_message = "Azure NSG must allow HTTPS (443) from AWS VPC CIDR."
  }
}

# ---------------------------------------------------------------------------
# Run 6: DNS zones configured for cross-cloud resolution
# ---------------------------------------------------------------------------

run "dns_zones_configured" {
  command = plan

  assert {
    condition     = aws_route53_zone.private.name == "aws.internal"
    error_message = "Route53 private zone should be named 'aws.internal'."
  }

  assert {
    condition     = azurerm_private_dns_zone.main.name == "azure.internal"
    error_message = "Azure Private DNS zone should be named 'azure.internal'."
  }

  assert {
    condition     = azurerm_private_dns_zone_virtual_network_link.main.registration_enabled == true
    error_message = "Azure DNS zone link should have auto-registration enabled."
  }
}

# ---------------------------------------------------------------------------
# Run 7: BGP ASN values are different (required for BGP peering)
# ---------------------------------------------------------------------------

run "bgp_asn_unique" {
  command = plan

  assert {
    condition     = var.aws_bgp_asn != var.azure_bgp_asn
    error_message = "AWS and Azure BGP ASNs must be different for BGP peering to work."
  }

  assert {
    condition     = var.aws_bgp_asn == 64512
    error_message = "AWS BGP ASN should be 64512."
  }

  assert {
    condition     = var.azure_bgp_asn == 65515
    error_message = "Azure BGP ASN should be 65515."
  }
}

# ---------------------------------------------------------------------------
# Run 8: DNS subnets are delegated to DNS resolver service
# ---------------------------------------------------------------------------

run "dns_subnet_delegation" {
  command = plan

  assert {
    condition = anytrue([
      for d in azurerm_subnet.dns_inbound.delegation :
      d.service_delegation[0].name == "Microsoft.Network/dnsResolvers"
    ])
    error_message = "DNS inbound subnet must be delegated to Microsoft.Network/dnsResolvers."
  }

  assert {
    condition = anytrue([
      for d in azurerm_subnet.dns_outbound.delegation :
      d.service_delegation[0].name == "Microsoft.Network/dnsResolvers"
    ])
    error_message = "DNS outbound subnet must be delegated to Microsoft.Network/dnsResolvers."
  }
}