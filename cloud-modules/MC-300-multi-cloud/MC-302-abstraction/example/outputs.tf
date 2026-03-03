# MC-302: Provider Abstraction Patterns - Outputs
# Demonstrates normalized outputs: same output names regardless of cloud

# ---------------------------------------------------------------------------
# Abstraction metadata
# ---------------------------------------------------------------------------

output "vm_size_abstract" {
  description = "Abstract VM size class used (small/medium/large)"
  value       = var.vm_size
}

output "aws_resolved_instance_type" {
  description = "Resolved AWS instance type from abstract size"
  value       = local.aws_instance_type
}

output "azure_resolved_vm_size" {
  description = "Resolved Azure VM size from abstract size"
  value       = local.azure_vm_size
}

output "size_map" {
  description = "Complete size mapping for both clouds"
  value       = local.size_map
}

# ---------------------------------------------------------------------------
# AWS outputs
# ---------------------------------------------------------------------------

output "aws_instance_id" {
  description = "AWS EC2 instance ID"
  value       = aws_instance.web.id
}

output "aws_instance_type_actual" {
  description = "Actual AWS instance type deployed"
  value       = aws_instance.web.instance_type
}

output "aws_private_ip" {
  description = "AWS instance private IP address"
  value       = aws_instance.web.private_ip
}

output "aws_vpc_id" {
  description = "AWS VPC ID"
  value       = aws_vpc.main.id
}

output "aws_subnet_id" {
  description = "AWS web subnet ID"
  value       = aws_subnet.web.id
}

# ---------------------------------------------------------------------------
# Azure outputs
# ---------------------------------------------------------------------------

output "azure_vm_id" {
  description = "Azure VM resource ID"
  value       = azurerm_linux_virtual_machine.web.id
}

output "azure_vm_size_actual" {
  description = "Actual Azure VM size deployed"
  value       = azurerm_linux_virtual_machine.web.size
}

output "azure_private_ip" {
  description = "Azure VM private IP address"
  value       = azurerm_network_interface.web.private_ip_address
}

output "azure_vnet_id" {
  description = "Azure VNet ID"
  value       = azurerm_virtual_network.main.id
}

output "azure_subnet_id" {
  description = "Azure web subnet ID"
  value       = azurerm_subnet.web.id
}

# ---------------------------------------------------------------------------
# Normalized multi-cloud outputs
# Same structure regardless of which cloud resources are active
# ---------------------------------------------------------------------------

output "web_servers" {
  description = "Normalized web server info from both clouds (interface pattern)"
  value = {
    aws = {
      id         = aws_instance.web.id
      private_ip = aws_instance.web.private_ip
      size       = aws_instance.web.instance_type
      cloud      = "aws"
    }
    azure = {
      id         = azurerm_linux_virtual_machine.web.id
      private_ip = azurerm_network_interface.web.private_ip_address
      size       = azurerm_linux_virtual_machine.web.size
      cloud      = "azure"
    }
  }
}