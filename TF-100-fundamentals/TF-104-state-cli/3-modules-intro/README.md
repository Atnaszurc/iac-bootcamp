# Modularizing Terraform Configurations

In this section, we'll focus on rewriting our Azure Virtual Machine and local file configurations into reusable modules. We'll also discuss best practices and important considerations when working with Terraform modules.

## Table of Contents

1. [Introduction](#modularizing-terraform-configurations)
2. [Task 1: Rewriting Configurations as Modules](#task-1-rewriting-configurations-as-modules)
   - [Azure Virtual Machine Module](#11-azure-virtual-machine-module)
   - [Local File Module](#12-local-file-module)
3. [Module Best Practices in Terraform](#module-best-practices-in-terraform)


## Task 1: Rewriting Configurations as Modules

### 1.1 Azure Virtual Machine Module

1. Start by creating new directories called `modules/azure`.
2. Copy the .tf files from your previous lab (or from the example folder) and paste it into the azure folder and remove the Terraform and provider blocks from the main.tf file. 
> This ensures that the module is self-contained and can be used in any environment without needing to modify the module, and that the calling module is responsible for providing the necessary inputs for provider configuration.
3. Finally, to use this module, you can call it in your root module like this:
```hcl
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=4.0.1"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

module "azure-vm" {
  source = "./modules/azure/"
  resource_group_name = "<your-resource-group>"
  server_name = "<your-server-name>"
  public_ssh_key = "<your-public-ssh-key>"
}

variable "resource_group_name" {
  type = string
}

variable "server_name" {
  type = string
}

variable "public_ssh_key" {
  type = string
}

variable "subscription_id" {
  type = string
}
```
And using a terraform.tfvars file to pass in the variables:
```hcl
resource_group_name = "<your-resource-group>"
server_name = "<your-server-name>"
public_ssh_key = "<your-public-ssh-key>"
```

Initialize Terraform, plan, and apply your changes:
```bash
terraform init
terraform plan
terraform apply
```

### 1.2 Local File Module

1. Create a new directory called `modules/local-file`.

2. Create a new file called `main.tf` in the `modules/local-file` directory and add the following code:
```hcl
resource "local_file" "example_map" {
  for_each = var.file_contents
  content  = each.value
  filename = "${path.module}/${var.environment}_${each.key}"
}
```

3. Create a new file called `variables.tf` in the `modules/local-file` directory and add the following code:
```hcl
variable "file_contents" {
  description = "Map of file names and their contents"
  type        = map(string)
}

variable "file_extension" {
  description = "File extension for created files"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}
```

4. Create a new file called `outputs.tf` in the `modules/local-file` directory and add the following code:

```hcl
output "created_files" {
  value = [for file in local_file.example_map : file.filename]
}
```

5. Create a new file called `local-file.tf` in your root folder and add the following code:
```hcl
terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "2.5.1"
    }
  }
}

provider "local" {}

module "file_creator" {
  source        = "./modules/local-file"
  file_contents = var.file_contents
  environment   = var.environment
  file_extension = var.file_extension
}
```

6. Create or add the following to your `variables.tf` file in the root directory:
```hcl
variable "file_contents" {
  description = "Map of file names and their contents"
  type        = map(string)
  default = {
    "file1.txt" = "This is the content of file 1"
    "file2.txt" = "Here's the content for file 2"
    "file3.txt" = "File 3 content goes here"
  }
}

variable "file_extension" {
  description = "File extension for created files"
  type        = string
  default     = "txt"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}
```
7. And finally create a new file called outputs.tf in the root directory and add the following code:
```hcl
output "created_files" {
  value = module.file_creator.created_files
}
```

8. Run the following commands to initialize Terraform, plan, and apply your changes:
```bash
terraform init
terraform plan
terraform apply
```


## Module Best Practices in Terraform

When working with modules in Terraform, it's important to follow these best practices to ensure maintainability, reusability, and scalability of your infrastructure code:

1. **Keep modules focused**: Each module should have a single, well-defined purpose. Avoid creating monolithic modules that try to do too much.

2. **Use consistent naming conventions**: Adopt a clear and consistent naming convention for your modules, variables, and outputs to improve readability and understanding.

3. **Provide clear documentation**: Include a README.md file in each module directory, explaining its purpose, inputs, outputs, and usage examples.

4. **Use variables for customization**: Parameterize your modules using input variables to make them flexible and reusable across different environments or use cases.

5. **Utilize outputs effectively**: Expose relevant information from your modules using outputs, allowing parent modules or the root configuration to access important data.

6. **Version your modules**: If sharing modules across multiple projects or teams, use version control and semantic versioning to manage changes and dependencies.

7. **Keep modules DRY (Don't Repeat Yourself)**: Avoid duplicating code across modules. If you find yourself repeating similar configurations, consider creating a new, more generic module.

8. **Use data sources when appropriate**: Leverage data sources to fetch existing resource information, making your modules more dynamic and reducing hard-coded values.

9. **Implement proper error handling**: Use validation blocks for input variables to ensure that users provide valid inputs to your modules.

10. **Follow the principle of least privilege**: When defining IAM roles or permissions within modules, grant only the minimum necessary permissions for the module to function.

11. **Use consistent formatting**: Utilize tools like `terraform fmt` to maintain consistent code formatting across your modules and configurations.

12. **Test your modules**: Implement automated tests for your modules using tools like Terratest to ensure they work as expected and catch potential issues early.

By adhering to these best practices, you can create more maintainable, reusable, and robust Terraform modules that will serve as building blocks for your infrastructure as code.

