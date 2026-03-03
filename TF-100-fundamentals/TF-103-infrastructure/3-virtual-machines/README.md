# Adding a Linux Virtual Machine to Azure Setup with Terraform

Objective: Create an Ubuntu Linux virtual machine in your Azure environment using Terraform.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Tasks](#tasks)
   - [Creating the Virtual Machine Configuration](#creating-the-virtual-machine-configuration)
   - [Using a Custom Packer Image (Optional)](#using-a-custom-packer-image-optional)
3. [Applying the Configuration](#applying-the-configuration)
4. [Verifying the Virtual Machine](#verifying-the-virtual-machine)
5. [Cleaning Up Resources](#cleaning-up-resources)

## Prerequisites:
- Completed the previous blocks on setting up a virtual network, subnet, and network security group
- Azure CLI installed
- Your own Resource Group
- Terraform CLI

## Tasks:

1. Create a new file called `virtual-machine.tf` in your project directory.

2. Add the following code to `virtual-machine.tf` to create a Linux virtual machine:
```hcl
resource "azurerm_linux_virtual_machine" "this" {
  name                = var.server_name
  resource_group_name = data.azurerm_resource_group.this.name
  location            = data.azurerm_resource_group.this.location
  size                = "Standard_F2s_v2"
  admin_username      = "ubuntu"
  network_interface_ids = [
    azurerm_network_interface.this.id,
  ]
  admin_ssh_key {
    username   = "ubuntu"
    public_key = var.public_ssh_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}
```

If you partook in the packer training, you can use the image you created there.
```hcl
data "azurerm_image" "this" {
  name                = "<your-image-name>"
  resource_group_name = var.resource_group_name
}
```
Remove the source_image_reference block, and exchange it for the source_image_id block:
```hcl
source_image_id = data.azurerm_image.this.id
```
3. Run `terraform plan` and `terraform apply` to create the virtual machine. 

Once you are happy with your results, and with any changes you incorporate, run `terraform destroy` to destroy the entire setup in preparation for the next block.
