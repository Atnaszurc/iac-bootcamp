# Azure Network Setup with Terraform

Objective: Create a virtual network and subnet in Azure using Terraform inside your existing resource group.

## Prerequisites:
- [Azure CLI installed](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
- Your own Resource Group
- Terraform CLI

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Table of Contents](#table-of-contents)
3. [Tasks](#tasks)
   - [Creating the Terraform Configuration](#creating-the-terraform-configuration)
   - [Configuring the Azure Provider](#configuring-the-azure-provider)
   - [Using Data Sources](#using-data-sources)
   - [Creating Network Resources](#creating-network-resources)
4. [Applying the Configuration](#applying-the-configuration)
5. [Verifying the Network Setup](#verifying-the-network-setup)

## Tasks:

1. Using your experience from the previous block, create your main.tf, variables.tf, terraform.tfvars file. 
2. Ensure you use the new required provider for this lab:
```hcl
azurerm = {
    source  = "hashicorp/azurerm"
    version = "=4.0.1"
}
```
3. Next we will be configuring the provider, which is easy since we are using the Azure CLI for logging in. Add the following to your provider block:
```hcl
provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}
```
4. Next we need to use a data source to get information about our resource group. Add the following to your main.tf file:
```hcl
data "azurerm_resource_group" "example" {
  name = var.resource_group_name
}
```

> A data source in Terraform is a read-only query that fetches information from an external source, such as a cloud provider or other infrastructure component. Data sources allow you to use existing resources or information in your Terraform configuration without managing them directly.
> Key points about data sources:
> 1. Read-only: Data sources don't create, modify, or delete resources. They only retrieve information.
> 2. External information: They fetch data from outside your Terraform configuration, like cloud provider APIs or other systems.
> 3. Use existing resources: Data sources let you reference and use properties of resources that already exist and aren't managed by your current Terraform configuration.
> 4. Dynamic configurations: They enable more dynamic and flexible Terraform configurations by allowing you to base your resource definitions on existing infrastructure.
> 5. Syntax: Data sources are defined using the `data` block in Terraform, similar to how resources are defined with the `resource` block.
> In the example provided, `data "azurerm_resource_group" "example"` is a data source that retrieves information about an existing Azure resource group. This allows you to use properties of the resource group (like its location) in other parts of your Terraform configuration without having to hardcode values or manage the resource group itself within this particular Terraform project.


5. Next we will be creating the network resources, starting with the virtual network. Add the following to your main.tf file:
```hcl

resource "azurerm_virtual_network" "example" {
  name                = "example-network"
  address_space       = ["10.0.0.0/16"]
  location            = data.azurerm_resource_group.example.location
  resource_group_name = data.azurerm_resource_group.example.name
}

resource "azurerm_subnet" "example" {
  name                 = "internal"
  resource_group_name  = data.azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "example" {
  name                = "example-nic"
  location            = data.azurerm_resource_group.example.location
  resource_group_name = data.azurerm_resource_group.example.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.example.id
    private_ip_address_allocation = "Dynamic"
  }
}
```

6. Finally, add your resource group name to your terraform.tfvars file.
```hcl
resource_group_name = "your-resource-group-name"
```

7. Login to Azure CLI using the following command and follow the prompts:
```bash
az login
```

8. Run the following commands to initialize Terraform, plan, and apply your changes:
```bash
terraform init
terraform plan
terraform apply
```

9. Verify that your resources have been created by running the following command:
```bash
az network nic list --resource-group your-resource-group-name
```

For simplicity, you can run the following command to set your default resource group:
```bash
az configure --defaults group=<your-resource-group-name>
```