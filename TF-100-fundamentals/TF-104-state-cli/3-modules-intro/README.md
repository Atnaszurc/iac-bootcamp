# Modularizing Terraform Configurations

In this section, we'll focus on rewriting our libvirt virtual machine and local file configurations into reusable modules. We'll also discuss best practices and important considerations when working with Terraform modules.

## Table of Contents

1. [Introduction](#modularizing-terraform-configurations)
2. [Task 1: Rewriting Configurations as Modules](#task-1-rewriting-configurations-as-modules)
   - [Libvirt Virtual Machine Module](#11-libvirt-virtual-machine-module)
   - [Local File Module](#12-local-file-module)
3. [Module Best Practices in Terraform](#module-best-practices-in-terraform)


## Task 1: Rewriting Configurations as Modules

### 1.1 Libvirt Virtual Machine Module

1. Start by creating a new directory called `modules/vm`.
2. Copy the .tf files from your previous lab (TF-103) into the `vm` folder and remove the `provider` block from `main.tf`. Keep the `terraform { required_providers { ... } }` block: a module has to say which providers it needs, but it shouldn't configure them.
> This ensures that the module is self-contained and can be used in any environment without needing to modify the module, and that the calling module is responsible for configuring the provider.
3. Turn the values that should differ per VM into variables: `vm_name`, `memory_mb`, `vcpu_count`, `network_cidr`, `base_image_url` and `ssh_public_key`. Every resource name must include `var.vm_name`, or two instances of the module would try to create a network, pool and VM with the same names.
4. Add outputs for what the caller needs, for example the VM name and its IP address:
```hcl
output "vm_name" {
  value = libvirt_domain.this.name
}

output "ip_address" {
  value = try(data.libvirt_domain_interface_addresses.this.interfaces[0].addrs[0].addr, null)
}
```
5. Finally, call the module twice from your root module, once for a web server and once for a database:
```hcl
terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.9"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

module "web_vm" {
  source = "./modules/vm"

  vm_name        = "${var.project_name}-web"
  base_image_url = var.base_image_url
  ssh_public_key = var.ssh_public_key
  memory_mb      = 1024
  vcpu_count     = 1
  network_cidr   = "10.50.1.0/24"
}

module "db_vm" {
  source = "./modules/vm"

  vm_name        = "${var.project_name}-db"
  base_image_url = var.base_image_url
  ssh_public_key = var.ssh_public_key
  memory_mb      = 2048
  vcpu_count     = 2
  network_cidr   = "10.50.2.0/24"
}

output "web_vm_ip" {
  value = module.web_vm.ip_address
}

output "db_vm_ip" {
  value = module.db_vm.ip_address
}

variable "project_name" {
  type = string
}

variable "base_image_url" {
  type = string
}

variable "ssh_public_key" {
  type = string
}
```
And using a terraform.tfvars file to pass in the variables:
```hcl
project_name   = "tf104-modules"
base_image_url = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
ssh_public_key = "<your-public-ssh-key>"
```

Initialize Terraform, plan, and apply your changes:
```bash
terraform init
terraform plan
terraform apply
```

Each VM ends up on its own network with an address from its own range:
```
db_vm_ip  = "10.50.2.150"
web_vm_ip = "10.50.1.137"
```

The [`example/`](./example/) folder has the complete module and root configuration, with tests. Try `terraform console -scope=module.db_vm` there to look at the module's variables from the inside (Terraform 1.16+).

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
      version = "~> 2.7"
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

12. **Test your modules**: Implement automated tests for your modules with `terraform test` (see [TF-303](../../../TF-300-advanced/TF-303-test-framework/README.md)) or tools like Terratest to ensure they work as expected and catch potential issues early.

By adhering to these best practices, you can create more maintainable, reusable, and robust Terraform modules that will serve as building blocks for your infrastructure as code.

