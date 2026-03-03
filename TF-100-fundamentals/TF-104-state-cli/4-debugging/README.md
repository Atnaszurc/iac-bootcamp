# Debugging Terraform: A Beginner's Guide


Debugging is an essential skill for working with Terraform. As you start building more complex infrastructure, you'll inevitably encounter issues. Here are some common debugging techniques and tools to help you troubleshoot your Terraform configurations.

## Table of Contents

1. [Use Verbose Logging](#1-use-verbose-logging)
2. [Terraform Console](#2-terraform-console)
3. [Break down complex configurations](#3-break-down-complex-configurations)
4. [Use Terraform Graph](#4-use-terraform-graph)
5. [Use Terraform Outputs](#5-use-terraform-outputs)
6. [Use Version Control](#6-use-version-control)

## 1. Use Verbose Logging

One of the simplest ways to get more information about what Terraform is doing is to increase the logging verbosity.

```bash
export TF_LOG=DEBUG
terraform apply
```

Logging levels: TRACE, DEBUG, INFO, WARN, ERROR

Remember to unset this when you're done:

```bash
unset TF_LOG
```

## 2. Terraform Console

Like you saw in block1 in the 5-cli module, the terraform console allows you to interact with your terraform code in a more interactive way.

## 3. Break down complex configurations

If your configuration is too big to debug all at once, try breaking it down into smaller chunks by modularizing your code.

## 4. Use Terraform Graph

The Terraform graph command can help you visualize the relationships between resources and modules in your configuration.

```bash
terraform graph
```

## 5. Use Terraform Outputs

Using outputs is a great way to debug your code. You can use the `terraform output` command to print out the values of your outputs. And add extra outputs to your code to help you debug.

```hcl
output "virtual_machine_id" {
  value = azurerm_linux_virtual_machine.this.id
}
```

```bash
terraform output
```

## 6. Use Version Control

Use version control to your advantage. You can use the `terraform plan` command to compare the current state of your configuration with the desired state.

```bash
terraform plan
```

Version controlled code allows for easy rollback of changes, and allows you to see the changes between each version.
