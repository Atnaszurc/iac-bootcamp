# AZ-204: Advanced Patterns
# Demonstrates: VM Scale Set, Azure Load Balancer, autoscaling
# Provider: hashicorp/azurerm
# Run: terraform init && terraform apply
#
# Prerequisites: Azure credentials configured (see AZ-201)
# Cost: VMSS instances billed per VM size; LB Standard ~$0.025/hour

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
# Data sources
# ─────────────────────────────────────────────────────────────────────────────

data "azurerm_client_config" "current" {}

# ─────────────────────────────────────────────────────────────────────────────
# Resource Group
# ─────────────────────────────────────────────────────────────────────────────

resource "azurerm_resource_group" "main" {
  name     = "${var.project_name}-rg"
  location = var.location

  tags = {
    ManagedBy   = "Terraform"
    Course      = "AZ-204"
    Environment = var.environment
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Networking
# ─────────────────────────────────────────────────────────────────────────────

resource "azurerm_virtual_network" "main" {
  name                = "${var.project_name}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = {
    ManagedBy = "Terraform"
  }
}

resource "azurerm_subnet" "main" {
  name                 = "vmss-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]
}

# ─────────────────────────────────────────────────────────────────────────────
# Public IP for Load Balancer
# ─────────────────────────────────────────────────────────────────────────────

resource "azurerm_public_ip" "lb" {
  name                = "${var.project_name}-lb-pip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    ManagedBy = "Terraform"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Azure Load Balancer
# ─────────────────────────────────────────────────────────────────────────────

resource "azurerm_lb" "main" {
  name                = "${var.project_name}-lb"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.lb.id
  }

  tags = {
    ManagedBy = "Terraform"
  }
}

resource "azurerm_lb_backend_address_pool" "main" {
  name            = "${var.project_name}-backend-pool"
  loadbalancer_id = azurerm_lb.main.id
}

resource "azurerm_lb_probe" "http" {
  name            = "http-probe"
  loadbalancer_id = azurerm_lb.main.id
  protocol        = "Http"
  port            = 80
  request_path    = "/"
}

resource "azurerm_lb_rule" "http" {
  name                           = "http-rule"
  loadbalancer_id                = azurerm_lb.main.id
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "PublicIPAddress"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.main.id]
  probe_id                       = azurerm_lb_probe.http.id
}

# ─────────────────────────────────────────────────────────────────────────────
# Network Security Group for VMSS
# ─────────────────────────────────────────────────────────────────────────────

resource "azurerm_network_security_group" "vmss" {
  name                = "${var.project_name}-vmss-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "allow-http"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-ssh"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.admin_cidr
    destination_address_prefix = "*"
  }

  tags = {
    ManagedBy = "Terraform"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Linux VM Scale Set
# ─────────────────────────────────────────────────────────────────────────────

resource "azurerm_linux_virtual_machine_scale_set" "main" {
  name                = "${var.project_name}-vmss"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = var.vm_sku
  instances           = var.instance_count
  admin_username      = var.admin_username

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.admin_ssh_public_key
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name    = "vmss-nic"
    primary = true

    network_security_group_id = azurerm_network_security_group.vmss.id

    ip_configuration {
      name                                   = "internal"
      primary                                = true
      subnet_id                              = azurerm_subnet.main.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.main.id]
    }
  }

  # Install nginx on boot
  custom_data = base64encode(<<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y nginx
    echo "<h1>Hello from $(hostname)</h1>" > /var/www/html/index.html
    systemctl enable nginx
    systemctl start nginx
  EOF
  )

  tags = {
    ManagedBy   = "Terraform"
    Environment = var.environment
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Autoscale Settings
# ─────────────────────────────────────────────────────────────────────────────

resource "azurerm_monitor_autoscale_setting" "main" {
  name                = "${var.project_name}-autoscale"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  target_resource_id  = azurerm_linux_virtual_machine_scale_set.main.id

  profile {
    name = "default"

    capacity {
      default = var.instance_count
      minimum = var.min_instances
      maximum = var.max_instances
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.main.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 75
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.main.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 25
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Outputs
# ─────────────────────────────────────────────────────────────────────────────

output "load_balancer_public_ip" {
  description = "Public IP address of the load balancer"
  value       = azurerm_public_ip.lb.ip_address
}

output "vmss_id" {
  description = "ID of the VM Scale Set"
  value       = azurerm_linux_virtual_machine_scale_set.main.id
}

output "vmss_name" {
  description = "Name of the VM Scale Set"
  value       = azurerm_linux_virtual_machine_scale_set.main.name
}

output "app_url" {
  description = "URL to access the application via load balancer"
  value       = "http://${azurerm_public_ip.lb.ip_address}"
}