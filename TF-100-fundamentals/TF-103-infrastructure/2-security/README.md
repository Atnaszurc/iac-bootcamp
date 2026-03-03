# Adding Network Security Groups to Azure Setup with Terraform

Objective: Enhance the security of your Azure virtual network by adding a Network Security Group (NSG) using Terraform.

## Prerequisites:
- Completed the previous block on setting up a virtual network and subnet
- Azure CLI installed
- Your own Resource Group
- Terraform CLI

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Tasks](#tasks)
   - [Creating a Network Security Group](#creating-a-network-security-group)
   - [Adding Security Rules](#adding-security-rules)
   - [Associating NSG with Network Interface](#associating-nsg-with-network-interface)
3. [Verifying the Network Security Group](#verifying-the-network-security-group)

## Tasks:

1. If you haven't already, create a new file called `security-group.tf` in your project directory.

2. Add the following code to `security-group.tf` to create a Network Security Group:
```hcl
resource "azurerm_network_security_group" "example" {
  name                = format("%s-secgroup", var.server_name)
  location            = data.azurerm_resource_group.this.location
  resource_group_name = data.azurerm_resource_group.this.name
}

resource "azurerm_network_security_rule" "ssh" {
  name                        = "ssh"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = data.azurerm_resource_group.this.name
  network_security_group_name = azurerm_network_security_group.this.name
}

resource "azurerm_network_interface_security_group_association" "this" {
  network_interface_id      = azurerm_network_interface.this.id
  network_security_group_id = azurerm_network_security_group.this.id
}
```

3. If you are using your previous code, you can now run `terraform plan` and `terraform apply` to create the NSG and associate it with your network interface.

4. Verify the NSG is created and associated correctly by using the following command:
```bash
az network nsg list
```

Add `--resouce-group <your-resource-group-name>` if you didn't set your default resource group.