# Terraform Functions for Beginners

Objective:In this training, you'll learn about common Terraform functions and how to use them in your configurations. 

## Table of Contents

1. [Introduction](#introduction)
2. [What are Terraform Functions?](#what-are-terraform-functions)
3. [Instructions](#instructions)
4. [Tasks](#tasks)
   - [Task 1: String Manipulation](#task-1-string-manipulation)
   - [Task 2: Length of a List](#task-2-length-of-a-list)
   - [Task 3: List Operations](#task-3-list-operations)
   - [Task 4: Map Operations](#task-4-map-operations)
   - [Task 5: Conditional Expressions](#task-5-conditional-expressions)
   - [Task 6: String Interpolation and Formatting](#task-6-string-interpolation-and-formatting)
   - [Task 7: Date and Time Functions](#task-7-date-and-time-functions)
   - [Task 8: Type Conversion](#task-8-type-conversion)
   - [Task 9: Working with Sets](#task-9-working-with-sets)

## What are Terraform Functions?
Terraform functions are built-in capabilities that allow you to transform and manipulate values in your configuration. They help you write more dynamic and flexible Terraform code.

## Instructions

1. Add the below new elements to your `main.tf` file.
2. Run `terraform init` if you haven't already.
3. Use `terraform console` to interactively explore these functions. For example:
  - Type `upper("hello")` to see how the `upper()` function works.
  - Try `length(var.file_contents)` to see the number of files.
4. Experiment with other expressions using the variables and functions introduced.
5. Run `terraform plan` to see how Terraform evaluates these new outputs.
6. Run `terraform apply` to create the resources and see the output values.

For more functions to try, see the [Terraform documentation](https://developer.hashicorp.com/terraform/language/functions).

## Tasks

### Task 1: String Manipulation

1. Add the following output to your `main.tf`:

```
output "upper_hello" {
  value = upper("hello")
}
```

2. Run `terraform plan` to see how Terraform evaluates this new output. 

### Task 2: Length of a List

1. Add the following output to your `main.tf`:

```hcl
output "uppercase_filenames" {
    value = [for filename in keys(var.file_contents) : upper(filename)]
}
```
2. Run `terraform apply` to see the result.
3. This demonstrates the `upper()` function and `keys()` function.

### Task 3: List Operations

1. Add this output to practice list manipulation:
```hcl
output "file_count" {
    value = length(var.file_contents)
}
```
2. Run `terraform apply` to see the result.
3. This shows how to use the `length()` function with a map.

### Task 4: Map Operations

1. Try this output to learn about map manipulation:
```hcl
output "file_contents_with_prefix" {
    value = {for k, v in var.file_contents : "prefix_${k}" => v}
}
```
2. Run `terraform apply` to see the result.
3. This demonstrates map transformation using a for expression.

### Task 5: Conditional Expressions

1. Modify the `local_file` resource to use a conditional expression:
```hcl
resource "local_file" "example_map" {
    for_each = var.file_contents
    content = each.value
    filename = var.environment == "prod" ? "${path.module}/prod_${each.key}" : "${path.module}/${var.environment}_${each.key}"
}
```
2. Run `terraform apply` to see the result.
3. This shows how to use the conditional (ternary) operator.

### Task 6: String Interpolation and Formatting

1. Add a new output to practice string formatting:
```hcl
output "formatted_file_info" {
    value = [for filename, content in var.file_contents : format("File %s has %d characters", filename, length(content))]
}
```
2. Run `terraform apply` to see the result.
3. This demonstrates how to format strings using the `format()` function and string interpolation.

### Task 7: Date and Time Functions

1. Add an output to show current timestamp:
```hcl
output "current_time" {
    value = formatdate("YYYY-MM-DD hh:mm:ss", timestamp())
}
```
2. Run `terraform apply` to see the result.
3. This shows how to use `formatdate()` and `timestamp()` functions.

### Task 8: Type Conversion

1. Add an output to practice type conversion:
```hcl
output "file_count_as_string" {
    value = tostring(length(var.file_contents))
}
```
2. Run `terraform apply` to see the result.
3. This demonstrates the `tostring()` function.

### Task 9: Working with Sets

1. Add a new variable and output to practice set operations:
```hcl
variable "tags" {
    type = list(string)
    default = ["tag1", "tag2", "tag3", "tag1"]
}
output "unique_tags" {
    value = toset(var.tags)
}
```
2. Run `terraform apply` to see the result.
3. This shows how to use `toset()` to remove duplicates from a list.