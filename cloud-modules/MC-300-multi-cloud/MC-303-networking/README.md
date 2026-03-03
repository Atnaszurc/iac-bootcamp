# MC-303: Cross-Cloud Networking

**Course**: MC-300 Multi-Cloud Architecture  
**Module**: MC-303  
**Duration**: 1 hour  
**Prerequisites**: MC-302 (Provider Abstraction Patterns)  
**Difficulty**: Advanced

---

## 📋 Table of Contents

1. [Course Overview](#course-overview)
2. [Learning Objectives](#learning-objectives)
3. [Cross-Cloud Networking Concepts](#cross-cloud-networking-concepts)
4. [VPN Connectivity](#vpn-connectivity)
5. [AWS to Azure VPN](#aws-to-azure-vpn)
6. [DNS Across Clouds](#dns-across-clouds)
7. [Private Connectivity Options](#private-connectivity-options)
8. [Network Security](#network-security)
9. [Best Practices](#best-practices)
10. [Hands-On Labs](#hands-on-labs)
11. [Checkpoint Quiz](#checkpoint-quiz)
12. [Additional Resources](#additional-resources)

---

## 🎯 Course Overview

This course covers the networking layer of multi-cloud architecture — how to connect AWS and Azure environments securely, manage DNS across clouds, and implement consistent network security policies. You'll learn to build the network backbone that enables multi-cloud workloads to communicate.

### What You'll Build

By the end of this course, you'll be able to:
- Design cross-cloud network topology
- Configure VPN connections between AWS and Azure
- Implement cross-cloud DNS resolution
- Apply consistent network security policies
- Choose between connectivity options (VPN, ExpressRoute/Direct Connect)

### Course Structure

```
MC-303-networking/
├── README.md                          # This file
└── example/
    ├── main.tf                        # Main configuration
    ├── aws-networking.tf              # AWS VPN and networking
    ├── azure-networking.tf            # Azure VPN and networking
    ├── dns.tf                         # Cross-cloud DNS
    ├── variables.tf                   # Input variables
    ├── outputs.tf                     # Output values
    └── versions.tf                    # Version constraints
```

---

## 🎓 Learning Objectives

After completing this course, you will be able to:

1. **Design Cross-Cloud Network Topology**
   - Plan IP address spaces to avoid overlap
   - Choose appropriate connectivity options
   - Design for latency and bandwidth requirements

2. **Configure VPN Connectivity**
   - Create VPN gateways in AWS and Azure
   - Establish site-to-site VPN tunnels
   - Configure BGP routing

3. **Manage Cross-Cloud DNS**
   - Configure DNS forwarding between clouds
   - Resolve private hostnames across clouds
   - Implement split-horizon DNS

4. **Implement Network Security**
   - Apply consistent security policies
   - Configure firewall rules for cross-cloud traffic
   - Monitor cross-cloud network flows

---

## 🌐 Cross-Cloud Networking Concepts

### IP Address Planning

**Critical**: Plan non-overlapping CIDR blocks before deployment.

```
AWS VPC:          10.0.0.0/16
  ├── us-east-1a: 10.0.1.0/24
  ├── us-east-1b: 10.0.2.0/24
  └── us-east-1c: 10.0.3.0/24

Azure VNet:       10.1.0.0/16
  ├── web-subnet: 10.1.1.0/24
  ├── app-subnet: 10.1.2.0/24
  └── db-subnet:  10.1.3.0/24

VPN Transit:      172.16.0.0/30
  ├── AWS side:   172.16.0.1
  └── Azure side: 172.16.0.2
```

### Connectivity Options

| Option | Latency | Bandwidth | Cost | Use Case |
|--------|---------|-----------|------|----------|
| Internet VPN | High | Low | Low | Dev/test |
| IPSec VPN | Medium | Medium | Medium | Production |
| AWS Direct Connect + Azure ExpressRoute | Low | High | High | Enterprise |
| Third-party SD-WAN | Variable | High | Medium | Complex topologies |

---

## 🔒 VPN Connectivity

### AWS VPN Gateway

```hcl
# aws-networking.tf

# VPN Gateway
resource "aws_vpn_gateway" "main" {
  vpc_id = aws_vpc.main.id
  
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-vpn-gw"
  })
}

# Customer Gateway (points to Azure VPN)
resource "aws_customer_gateway" "azure" {
  bgp_asn    = 65000  # Azure default ASN
  ip_address = azurerm_public_ip.vpn_gw.ip_address
  type       = "ipsec.1"
  
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-azure-cgw"
  })
}

# VPN Connection
resource "aws_vpn_connection" "to_azure" {
  vpn_gateway_id      = aws_vpn_gateway.main.id
  customer_gateway_id = aws_customer_gateway.azure.id
  type                = "ipsec.1"
  static_routes_only  = false  # Use BGP
  
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-to-azure"
  })
}

# Route propagation
resource "aws_vpn_gateway_route_propagation" "main" {
  vpn_gateway_id = aws_vpn_gateway.main.id
  route_table_id = aws_route_table.private.id
}

# Outputs needed for Azure configuration
output "aws_vpn_tunnel1_address" {
  value = aws_vpn_connection.to_azure.tunnel1_address
}

output "aws_vpn_tunnel1_preshared_key" {
  value     = aws_vpn_connection.to_azure.tunnel1_preshared_key
  sensitive = true
}

output "aws_vpn_tunnel2_address" {
  value = aws_vpn_connection.to_azure.tunnel2_address
}
```

### Azure VPN Gateway

```hcl
# azure-networking.tf

# Public IP for VPN Gateway
resource "azurerm_public_ip" "vpn_gw" {
  name                = "${var.project_name}-vpn-pip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Gateway Subnet (required name)
resource "azurerm_subnet" "gateway" {
  name                 = "GatewaySubnet"  # Must be exactly this name
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.1.255.0/27"]
}

# Virtual Network Gateway
resource "azurerm_virtual_network_gateway" "main" {
  name                = "${var.project_name}-vpn-gw"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  type                = "Vpn"
  vpn_type            = "RouteBased"
  sku                 = "VpnGw1"
  enable_bgp          = true
  
  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.vpn_gw.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.gateway.id
  }
  
  bgp_settings {
    asn = 65515  # Azure default ASN
  }
}

# Local Network Gateway (represents AWS)
resource "azurerm_local_network_gateway" "aws" {
  name                = "${var.project_name}-aws-lng"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  gateway_address     = data.terraform_remote_state.aws.outputs.aws_vpn_tunnel1_address
  
  address_space = ["10.0.0.0/16"]  # AWS VPC CIDR
  
  bgp_settings {
    asn                 = 64512  # AWS ASN
    bgp_peering_address = "169.254.21.1"
  }
}

# VPN Connection to AWS
resource "azurerm_virtual_network_gateway_connection" "to_aws" {
  name                = "${var.project_name}-to-aws"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  
  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.main.id
  local_network_gateway_id   = azurerm_local_network_gateway.aws.id
  
  shared_key = data.terraform_remote_state.aws.outputs.aws_vpn_tunnel1_preshared_key
  
  enable_bgp = true
}
```

---

## 🌍 DNS Across Clouds

### DNS Architecture

```
AWS Private DNS:   *.aws.internal  → Route53 Private Hosted Zone
Azure Private DNS: *.azure.internal → Azure Private DNS Zone

Cross-cloud resolution:
  AWS → Azure: Forward *.azure.internal to Azure DNS resolver
  Azure → AWS: Forward *.aws.internal to Route53 Resolver
```

### AWS Route53 Private Hosted Zone

```hcl
# dns.tf (AWS side)

# Private hosted zone for AWS resources
resource "aws_route53_zone" "private" {
  name = "aws.internal"
  
  vpc {
    vpc_id = aws_vpc.main.id
  }
  
  tags = local.common_tags
}

# DNS record for AWS service
resource "aws_route53_record" "web" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "web.aws.internal"
  type    = "A"
  ttl     = 300
  records = [aws_instance.web.private_ip]
}

# Route53 Resolver - Inbound endpoint (for Azure to query)
resource "aws_route53_resolver_endpoint" "inbound" {
  name      = "${var.project_name}-inbound"
  direction = "INBOUND"
  
  security_group_ids = [aws_security_group.dns.id]
  
  ip_address {
    subnet_id = aws_subnet.private_a.id
  }
  
  ip_address {
    subnet_id = aws_subnet.private_b.id
  }
}

# Route53 Resolver - Outbound endpoint (to query Azure)
resource "aws_route53_resolver_endpoint" "outbound" {
  name      = "${var.project_name}-outbound"
  direction = "OUTBOUND"
  
  security_group_ids = [aws_security_group.dns.id]
  
  ip_address {
    subnet_id = aws_subnet.private_a.id
  }
  
  ip_address {
    subnet_id = aws_subnet.private_b.id
  }
}

# Forward azure.internal queries to Azure DNS
resource "aws_route53_resolver_rule" "azure" {
  domain_name          = "azure.internal"
  name                 = "forward-to-azure"
  rule_type            = "FORWARD"
  resolver_endpoint_id = aws_route53_resolver_endpoint.outbound.id
  
  target_ip {
    ip   = azurerm_private_dns_resolver_inbound_endpoint.main.ip_configurations[0].private_ip_address
    port = 53
  }
}

resource "aws_route53_resolver_rule_association" "azure" {
  resolver_rule_id = aws_route53_resolver_rule.azure.id
  vpc_id           = aws_vpc.main.id
}
```

### Azure Private DNS

```hcl
# dns.tf (Azure side)

# Private DNS Zone for Azure resources
resource "azurerm_private_dns_zone" "main" {
  name                = "azure.internal"
  resource_group_name = azurerm_resource_group.main.name
}

# Link DNS zone to VNet
resource "azurerm_private_dns_zone_virtual_network_link" "main" {
  name                  = "${var.project_name}-dns-link"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.main.name
  virtual_network_id    = azurerm_virtual_network.main.id
  registration_enabled  = true  # Auto-register VM hostnames
}

# DNS record for Azure service
resource "azurerm_private_dns_a_record" "web" {
  name                = "web"
  zone_name           = azurerm_private_dns_zone.main.name
  resource_group_name = azurerm_resource_group.main.name
  ttl                 = 300
  records             = [azurerm_network_interface.web.private_ip_address]
}

# DNS Private Resolver (for cross-cloud DNS)
resource "azurerm_private_dns_resolver" "main" {
  name                = "${var.project_name}-dns-resolver"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  virtual_network_id  = azurerm_virtual_network.main.id
}

# Inbound endpoint (AWS queries come here)
resource "azurerm_private_dns_resolver_inbound_endpoint" "main" {
  name                    = "${var.project_name}-inbound"
  private_dns_resolver_id = azurerm_private_dns_resolver.main.id
  location                = azurerm_resource_group.main.location
  
  ip_configurations {
    private_ip_allocation_method = "Dynamic"
    subnet_id                    = azurerm_subnet.dns_inbound.id
  }
}

# Outbound endpoint (Azure queries go here)
resource "azurerm_private_dns_resolver_outbound_endpoint" "main" {
  name                    = "${var.project_name}-outbound"
  private_dns_resolver_id = azurerm_private_dns_resolver.main.id
  location                = azurerm_resource_group.main.location
  subnet_id               = azurerm_subnet.dns_outbound.id
}

# Forwarding ruleset for AWS DNS
resource "azurerm_private_dns_resolver_dns_forwarding_ruleset" "main" {
  name                                       = "${var.project_name}-ruleset"
  resource_group_name                        = azurerm_resource_group.main.name
  location                                   = azurerm_resource_group.main.location
  private_dns_resolver_outbound_endpoint_ids = [azurerm_private_dns_resolver_outbound_endpoint.main.id]
}

# Forward aws.internal to Route53
resource "azurerm_private_dns_resolver_forwarding_rule" "aws" {
  name                      = "forward-to-aws"
  dns_forwarding_ruleset_id = azurerm_private_dns_resolver_dns_forwarding_ruleset.main.id
  domain_name               = "aws.internal."
  enabled                   = true
  
  target_dns_servers {
    ip_address = aws_route53_resolver_endpoint.inbound.ip_address[0].ip
    port       = 53
  }
}
```

---

## 🔐 Network Security

### Security Group for Cross-Cloud Traffic

```hcl
# AWS Security Group - Allow Azure traffic
resource "aws_security_group" "cross_cloud" {
  name        = "${var.project_name}-cross-cloud-sg"
  description = "Allow traffic from Azure VNet"
  vpc_id      = aws_vpc.main.id
  
  # Allow all traffic from Azure VNet
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.1.0.0/16"]  # Azure VNet CIDR
    description = "Allow all from Azure VNet"
  }
  
  # Allow specific ports only (more secure)
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.1.0.0/16"]
    description = "HTTPS from Azure"
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = local.common_tags
}
```

```hcl
# Azure NSG - Allow AWS traffic
resource "azurerm_network_security_group" "cross_cloud" {
  name                = "${var.project_name}-cross-cloud-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  
  security_rule {
    name                       = "AllowFromAWS"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "10.0.0.0/16"  # AWS VPC CIDR
    destination_address_prefix = "*"
    description                = "Allow HTTPS from AWS VPC"
  }
}
```

---

## ✅ Best Practices

### 1. Plan IP Spaces Before Deployment

```hcl
# Document your IP allocation
# AWS:   10.0.0.0/16  (65,536 addresses)
# Azure: 10.1.0.0/16  (65,536 addresses)
# VPN:   172.16.0.0/30 (transit)
# Never overlap these ranges!

variable "aws_vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "azure_vnet_cidr" {
  default = "10.1.0.0/16"
}
```

### 2. Use BGP for Dynamic Routing

```hcl
# ✅ BGP enables automatic route propagation
resource "aws_vpn_connection" "to_azure" {
  static_routes_only = false  # Use BGP
}

# ❌ Static routes require manual updates
resource "aws_vpn_connection" "to_azure" {
  static_routes_only = true  # Avoid in production
}
```

### 3. Monitor VPN Tunnel Health

```hcl
resource "aws_cloudwatch_metric_alarm" "vpn_tunnel_down" {
  alarm_name          = "${var.project_name}-vpn-tunnel-down"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "TunnelState"
  namespace           = "AWS/VPN"
  period              = 60
  statistic           = "Maximum"
  threshold           = 1
  alarm_description   = "VPN tunnel to Azure is down"
  
  dimensions = {
    VpnId = aws_vpn_connection.to_azure.id
  }
}
```

### 4. Use Redundant Tunnels

```hcl
# AWS VPN provides 2 tunnels automatically
# Configure both in Azure for redundancy
resource "azurerm_local_network_gateway" "aws_tunnel2" {
  name            = "${var.project_name}-aws-lng-2"
  gateway_address = data.terraform_remote_state.aws.outputs.aws_vpn_tunnel2_address
  # ...
}
```

---

## 🔬 Hands-On Labs

### Lab 1: IP Address Planning (10 minutes)

**Objective**: Design a non-overlapping IP address scheme for multi-cloud.

**Tasks**:
1. Define CIDR blocks for AWS VPC (10.0.0.0/16)
2. Define CIDR blocks for Azure VNet (10.1.0.0/16)
3. Plan subnets within each network
4. Reserve a transit range for VPN (172.16.0.0/30)
5. Document the IP allocation in variables.tf
6. Verify no overlaps using CIDR calculations

**Expected Output**:
- Non-overlapping IP scheme documented
- Variables defined for all CIDR blocks
- Clear subnet allocation plan

---

### Lab 2: VPN Gateway Setup (25 minutes)

**Objective**: Create VPN gateways in both AWS and Azure.

**Tasks**:
1. Create AWS VPN Gateway and attach to VPC
2. Create Azure VPN Gateway (VpnGw1 SKU)
3. Create Customer Gateway in AWS pointing to Azure IP
4. Create Local Network Gateway in Azure pointing to AWS
5. Establish VPN connection between them
6. Verify tunnel state is UP

**Note**: VPN Gateway provisioning takes 30-45 minutes in Azure.

**Expected Output**:
- VPN gateways in both clouds
- VPN connection established
- Tunnel state: Connected

---

### Lab 3: Cross-Cloud DNS (20 minutes)

**Objective**: Configure DNS so AWS resources can resolve Azure hostnames.

**Tasks**:
1. Create Route53 private hosted zone (aws.internal)
2. Create Azure Private DNS zone (azure.internal)
3. Create DNS records in each zone
4. Configure Route53 Resolver outbound endpoint
5. Create forwarding rule for azure.internal
6. Test DNS resolution from AWS to Azure

**Expected Output**:
- DNS zones in both clouds
- Cross-cloud DNS forwarding configured
- `nslookup web.azure.internal` resolves from AWS

---

## 📝 Checkpoint Quiz

### Question 1: IP Planning
**Why must AWS VPC and Azure VNet CIDR blocks not overlap?**

A) Cloud providers require unique CIDRs  
B) Overlapping CIDRs prevent VPN routing from knowing which cloud to send traffic to  
C) It's a Terraform limitation  
D) For cost optimization

<details>
<summary>Click to reveal answer</summary>

**Answer: B) Overlapping CIDRs prevent VPN routing from knowing which cloud to send traffic to**

When CIDRs overlap, the routing table can't determine whether traffic for 10.0.1.5 should go to AWS or Azure. Non-overlapping CIDRs ensure unambiguous routing across the VPN tunnel.
</details>

---

### Question 2: GatewaySubnet
**Why must the Azure VPN Gateway subnet be named exactly "GatewaySubnet"?**

A) It's a Terraform requirement  
B) Azure requires this specific name for the gateway subnet  
C) It's a DNS convention  
D) For BGP routing to work

<details>
<summary>Click to reveal answer</summary>

**Answer: B) Azure requires this specific name for the gateway subnet**

Azure's Virtual Network Gateway service specifically looks for a subnet named "GatewaySubnet" to deploy the gateway infrastructure. Any other name will cause deployment to fail.
</details>

---

### Question 3: BGP vs Static Routes
**What is the advantage of using BGP over static routes for VPN?**

A) BGP is cheaper  
B) BGP automatically propagates route changes without manual updates  
C) BGP provides encryption  
D) BGP is faster

<details>
<summary>Click to reveal answer</summary>

**Answer: B) BGP automatically propagates route changes without manual updates**

BGP dynamically exchanges routing information between peers. When new subnets are added, BGP automatically advertises them. Static routes require manual updates every time the network topology changes.
</details>

---

### Question 4: DNS Forwarding
**What is the purpose of Route53 Resolver forwarding rules?**

A) To cache DNS responses  
B) To forward DNS queries for specific domains to external DNS servers  
C) To block DNS queries  
D) To encrypt DNS traffic

<details>
<summary>Click to reveal answer</summary>

**Answer: B) To forward DNS queries for specific domains to external DNS servers**

Forwarding rules tell Route53 Resolver to send queries for specific domains (like `azure.internal`) to designated DNS servers (like Azure's DNS resolver) instead of resolving them locally.
</details>

---

### Question 5: VPN Redundancy
**Why does AWS provide two VPN tunnels per VPN connection?**

A) For load balancing  
B) For redundancy - if one tunnel fails, traffic fails over to the second  
C) For encryption key rotation  
D) Required by BGP

<details>
<summary>Click to reveal answer</summary>

**Answer: B) For redundancy - if one tunnel fails, traffic fails over to the second**

AWS automatically creates two IPSec tunnels per VPN connection, each terminating on different AWS endpoints. This provides high availability - if one tunnel or endpoint fails, traffic automatically uses the second tunnel.
</details>

---

### Question 6: Private DNS Zone
**What does enabling `registration_enabled = true` on an Azure Private DNS zone link do?**

A) Requires registration to access the zone  
B) Automatically creates DNS records for VMs in the linked VNet  
C) Enables public DNS resolution  
D) Registers the zone with ICANN

<details>
<summary>Click to reveal answer</summary>

**Answer: B) Automatically creates DNS records for VMs in the linked VNet**

When auto-registration is enabled, Azure automatically creates and removes A records in the private DNS zone as VMs are created and deleted in the linked VNet. This eliminates manual DNS record management.
</details>

---

## 📚 Additional Resources

### Official Documentation
- [AWS VPN Documentation](https://docs.aws.amazon.com/vpn/latest/s2svpn/VPC_VPN.html)
- [Azure VPN Gateway Documentation](https://docs.microsoft.com/en-us/azure/vpn-gateway/)
- [Route53 Resolver](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/resolver.html)
- [Azure Private DNS Resolver](https://docs.microsoft.com/en-us/azure/dns/dns-private-resolver-overview)

### Next Steps
- **Next Course**: [MC-304: Advanced Multi-Cloud Patterns](../MC-304-advanced-patterns/README.md)
- **Previous Course**: [MC-302: Provider Abstraction Patterns](../MC-302-abstraction/README.md)

---

*Part of the [Hashi-Training](../../../README.md) curriculum - MC-300: Multi-Cloud Architecture*