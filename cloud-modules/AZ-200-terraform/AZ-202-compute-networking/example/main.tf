# AZ-202: Compute & Networking
# Demonstrates: Resource Group, VNet, subnet, NSG, public IP, NIC, Linux VM
# Provider: hashicorp/azurerm
# Run: terraform init && terraform apply
#
# Prerequisites: Azure credentials configured (see AZ-201)
# Cost: Standard_B1s VM ~$0.012/hour (free tier eligible first 12 months)

terraform {
  required_version = ">= 1.14"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

# ─────────────────────────────────────────────────────────────────────────────
# Resource Group
# ─────────────────────────────────────────────────────────────────────────────

resource "azurerm_resource_group" "main" {
  name     = "${var.project_name}-rg"
  location = var.location

  tags = {
    ManagedBy   = "Terraform"
    Course      = "AZ-202"
    Environment = var.environment
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Virtual Network & Subnet
# ─────────────────────────────────────────────────────────────────────────────

resource "azurerm_virtual_network" "main" {
  name                = "${var.project_name}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet" "main" {
  name                 = "${var.project_name}-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]
}

# ─────────────────────────────────────────────────────────────────────────────
# Network Security Group
# ─────────────────────────────────────────────────────────────────────────────

resource "azurerm_network_security_group" "main" {
  name                = "${var.project_name}-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.allowed_ssh_cidr
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "main" {
  subnet_id                 = azurerm_subnet.main.id
  network_security_group_id = azurerm_network_security_group.main.id
}

# ─────────────────────────────────────────────────────────────────────────────
# Public IP & NIC
# ─────────────────────────────────────────────────────────────────────────────

resource "azurerm_public_ip" "main" {
  name                = "${var.project_name}-pip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "main" {
  name                = "${var.project_name}-nic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.main.id
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Linux Virtual Machine
# ─────────────────────────────────────────────────────────────────────────────

resource "azurerm_linux_virtual_machine" "main" {
  name                = "${var.project_name}-vm"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = var.vm_size
  admin_username      = "azureuser"

  network_interface_ids = [azurerm_network_interface.main.id]

  admin_ssh_key {
    username   = "azureuser"
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  custom_data = base64encode(<<-EOT
    #!/bin/bash
    apt-get update -y
    apt-get install -y nginx
    systemctl enable nginx
    systemctl start nginx
    echo "<h1>Hello from Terraform AZ-202!</h1>" > /var/www/html/index.html
  EOT
  )

  tags = {
    ManagedBy   = "Terraform"
    Course      = "AZ-202"
    Environment = var.environment
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Outputs
# ─────────────────────────────────────────────────────────────────────────────

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "vm_public_ip" {
  description = "Public IP address of the VM"
  value       = azurerm_public_ip.main.ip_address
}

output "web_url" {
  description = "URL to access the web server"
  value       = "http://${azurerm_public_ip.main.ip_address}"
}

output "ssh_command" {
  description = "SSH command to connect to the VM"
  value       = "ssh azureuser@${azurerm_public_ip.main.ip_address}"
}