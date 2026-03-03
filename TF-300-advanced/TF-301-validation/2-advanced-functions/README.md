# Advanced Terraform Functions and Provider-Defined Functions

## Introduction

This lesson covers advanced usage of Terraform functions, including function chaining and the new provider-defined functions introduced in Terraform 1.8. We'll focus on Azure-specific examples and use cases.

## Table of Contents
- [Function Chaining](#function-chaining)
- [Provider-Defined Functions (Azure)](#provider-defined-functions-azure)
- [Combining Built-in and Provider-Defined Functions](#combining-built-in-and-provider-defined-functions)
- [Best Practices](#best-practices)
- [Tasks](#tasks)
- [Task 1: Resource Naming Convention](#task-1-resource-naming-convention)
- [Task 2: Tag Manipulation](#task-2-tag-manipulation)
- [Task 3: Resource ID Parsing and Formatting](#task-3-resource-id-parsing-and-formatting)
- [Task 4: Subnet CIDR Calculation](#task-4-subnet-cidr-calculation)
- [Task 5: Resource ID Normalization and Validation](#task-5-resource-id-normalization-and-validation)
- [Task 6: Naming Function with Lookup and Error Handling](#task-6-naming-function-with-lookup-and-error-handling)


## Function Chaining

Function chaining involves using the output of one function as the input for another. This technique allows for complex data transformations in a single expression.

### Example: Formatting and Manipulating Strings

```hcl
locals {
  raw_name = "MY-APP-PROD-001"
  formatted_name = lower(replace(local.raw_name, "-", ""))
}
output "formatted_name" {
  value = local.formatted_name
}
```

In this example, we chain the `lower()` and `replace()` functions to transform the string.

### Example: Complex Data Manipulation

````hcl
variable "tags" {
  type = map(string)
  default = {
    "Environment" = "Production"
    "Project"     = "MyApp"
    "Owner"       = "DevOps Team"
  }
}

locals {
  tag_list = [for k, v in var.tags : "${upper(k)}:${title(v)}"]
  tag_string = join(", ", local.tag_list)
}

output "formatted_tags" {
  value = local.tag_string
}
````


Here, we use a combination of `for` expression, `upper()`, `title()`, and `join()` functions to transform a map of tags into a formatted string.

## Provider-Defined Functions (Azure)

Azure provider introduces two useful functions: `parse_resource_id` and `normalise_resource_id`.

### parse_resource_id

This function parses an Azure resource ID and returns its components.

````hcl
locals {
  resource_id = "/subscriptions/12345678-1234-9876-4563-123456789012/resourceGroups/myRG/providers/Microsoft.Network/virtualNetworks/myVNet"
  parsed_id = provider::azurerm::parse_resource_id(local.resource_id)
}

output "resource_group" {
  value = local.parsed_id.resource_group_name
}

output "resource_type" {
  value = local.parsed_id.resource_type
}

output "resource_name" {
  value = local.parsed_id.resource_name
}
````


### normalise_resource_id

This function normalizes an Azure resource ID, ensuring consistent formatting.

````hcl
locals {
  messy_id = "/Subscriptions/12345678-1234-9876-4563-123456789012/resourceGroups/myRG/PROVIDERS/Microsoft.Network/virtualNetworks/myVNet"
  clean_id = provider::azurerm::normalise_resource_id(local.messy_id)
}

output "normalized_id" {
  value = local.clean_id
}
````


## Combining Built-in and Provider-Defined Functions

You can combine Terraform's built-in functions with provider-defined functions for powerful transformations.

````hcl
locals {
  resource_ids = [
    "/subscriptions/12345678-1234-9876-4563-123456789012/resourceGroups/myRG1/providers/Microsoft.Network/virtualNetworks/myVNet1",
    "/subscriptions/12345678-1234-9876-4563-123456789012/resourceGroups/myRG2/providers/Microsoft.Network/virtualNetworks/myVNet2"
  ]
  
  vnet_names = [for id in local.resource_ids : provider::azurerm::parse_resource_id(id).resource_name]
  uppercase_names = [for name in local.vnet_names : upper(name)]
}

output "vnet_names" {
  value = local.uppercase_names
}

# Output: ["MYVNET1", "MYVNET2"]
````


This example combines the `parse_resource_id` provider-defined function with Terraform's built-in `upper()` function and list comprehension.

## Best Practices

1. Use function chaining to simplify complex transformations.
2. Leverage provider-defined functions for provider-specific operations.
3. Combine built-in and provider-defined functions for powerful data manipulation.
4. Use descriptive names for locals to improve readability when chaining functions.

## Tasks


## Task 1: Resource Naming Convention

Create a function chain that generates a standardized name for Azure resources:
- Start with a base name (e.g., "myapp")
- Add the environment (e.g., "prod", "dev")
- Add a random suffix
- Ensure the final name is lowercase and uses hyphens instead of spaces
- Limit the total length to 24 characters (for storage account compatibility)

### Example
```hcl
variable "base_name" {
    type = string
    default = "myapp"
}
variable "environment" {
    type = string
    default = "dev"
}
resource "random_string" "suffix" {
    length = 6
    special = false
    upper = false
}
locals {
    full_name = "${var.base_name}-${var.environment}-${random_string.suffix.result}"
    standardized_name = lower(replace(substr(local.full_name, 0, 24), " ", "-"))
}
output "resource_name" {
    value = local.standardized_name
}
```

## Task 2: Tag Manipulation
Given a map of tags, create a function chain that:
- Converts all keys to uppercase
- Prefixes all values with the key
- Joins the resulting key-value pairs into a single string
- Limits the total length to 512 characters (Azure's tag value limit)

### Example
```hcl 
variable "tags" { 
    type = map(string) 
    default = { 
        "environment" = "production" 
        "project" = "myproject" 
        "owner" = "devops team" 
    }
}
locals { 
    formatted_tags = [for k, v in var.tags : "${upper(k)}:${k}-${v}"] 
    tag_string = substr(join(", ", local.formatted_tags), 0, 512)
}
output "tag_string" { 
    value = local.tag_string
}
```
## Task 3: Resource ID Parsing and Formatting
Use the `parse_resource_id` provider-defined function to:
- Extract the resource group, resource type, and resource name from a given Azure resource ID
- Extract the resource group, resource type, and resource name from a given Azure resource ID
- Format these components into a string: "NAME (TYPE) in RESOURCE_GROUP"
- Convert the resource type to title case (e.g., "virtualNetworks" to "Virtual Networks")

Example
```hcl
variable "resource_id" { 
    type = string 
    default = "/subscriptions/12345678-1234-9876-4563-123456789012/resourceGroups/myRG/providers/Microsoft.Network/virtualNetworks/myVNet"
}
locals { 
    parsed_id = provider::azurerm::parse_resource_id(var.resource_id) 
    resource_type_formatted = title(replace(local.parsed_id.resource_type, "/([A-Z])/", " $1")) 
    formatted_string = "${local.parsed_id.resource_name} (${local.resource_type_formatted}) in ${local.parsed_id.resource_group_name}"
}
output "formatted_resource_info" { 
    value = local.formatted_string
}
```
## Task 4: Subnet CIDR Calculation
Create a function chain that:
- Starts with a VNet address space (e.g., "10.0.0.0/16")
- Calculates 4 equal-sized subnet CIDRs within that space
- Returns the list of subnet CIDRs

### Example
```hcl
variable "vnet_cidr" {  
    type = string
    default = "10.0.0.0/16"
}
locals { 
    vnet_address = cidrsubnets(var.vnet_cidr, 2, 2, 2, 2)
}
output "subnet_cidrs" { 
    value = local.vnet_address
}
```

## Task 5: Resource ID Normalization and Validation
Use both `parse_resource_id` and `normalise_resource_id` to:
- Normalize a given (potentially messy) Azure resource ID
- Validate that the normalized ID belongs to a specific resource type (e.g., only accept Storage Account IDs)
- If valid, return the storage account name; if not, return an error message

### Example
```hcl
variable "resource_id" { 
    type = string 
    default = "/subscriptions/12345678-1234-9876-4563-123456789012/resourceGroups/myRG/providers/Microsoft.Storage/storageAccounts/mystorageaccount"
}
locals { 
    normalized_id = provider::azurerm::normalise_resource_id(var.resource_id) 
    parsed_id = provider::azurerm::parse_resource_id(local.normalized_id) 
    is_storage_account = local.parsed_id.resource_type == "storageAccounts" 
    storage_account_name = local.is_storage_account ? local.parsed_id.resource_name : "Error: Not a storage account ID"
}
output "result" { 
    value = local.storage_account_name
}
```

## Task 6: Naming Function with Lookup and Error Handling
Create a naming function that:
- Takes inputs for service name, environment, and location
- Uses a lookup table to convert location names to short codes (e.g., "East US" to "eus")
- Generates a unique suffix based on the current date and a random number
- Generates a unique suffix based on the current date and a random number
- Assembles these components into a name that follows Azure naming rules for a specific resource type (e.g., App Service)
- Handles errors gracefully (e.g., invalid inputs)
Remember to use clear variable names and add comments to explain complex parts of your function chains.

### Example
```hcl
variable "service_name" { 
    type = string
}
variable "environment" { 
    type = string
}
variable "location" { 
    type = string
}
locals { 
    location_codes = { "East US" = "eus" "West US" = "wus" "North Europe" = "neu" "West Europe" = "weu" } 
    current_date = formatdate("YYMMDD", timestamp()) 
    random_suffix = random_string.suffix.result 
    name_components = [ lower(var.service_name), lower(var.environment), lookup(local.location_codes, var.location, "unk"), local.current_date, local.random_suffix ] 
    app_service_name = join("-", slice(local.name_components, 0, min(length(local.name_components), floor((60 - length(join("", local.name_components))) / (length(local.name_components) - 1))) ))
}
resource "random_string" "suffix" { 
    length = 4 
    special = false 
    upper = false
}
output "app_service_name" { 
    value = local.app_service_name
}
```