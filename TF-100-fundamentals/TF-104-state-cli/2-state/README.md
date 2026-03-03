# Terraform State Management for Beginners

In this training, you'll learn about Terraform state and some basic state manipulation techniques. We'll use the `example/main.tf` file or the one you created in the previous exercise for the following steps for our exercises:

## Table of Contents

1. [Introduction](#introduction)
2. [What is Terraform State?](#what-is-terraform-state)
3. [Tasks](#tasks)
   - [Task 1: Examine the State File](#task-1-examine-the-state-file)
   - [Task 2: Use terraform show](#task-2-use-terraform-show)
   - [Task 3: List Resources in the State](#task-3-list-resources-in-the-state)
   - [Task 4: Show a Specific Resource](#task-4-show-a-specific-resource)
   - [Task 5: Remove a Resource from State](#task-5-remove-a-resource-from-state)
   - [Task 6: Import a Resource](#task-6-import-a-resource)
   - [Task 7: Move a Resource in State](#task-7-move-a-resource-in-state)
   - [Task 8: Refresh State](#task-8-refresh-state)

## What is Terraform State?
Terraform state is a JSON file that keeps track of the resources Terraform manages and their current configuration. It maps the resources in your configuration to real-world resources in your infrastructure.


## Tasks

### Task 1: Examine the State File

1. Set the environment variable:
```
export TF_VAR_environment=dev  # For Linux/macOS
set TF_VAR_environment=dev     # For Windows
```
2. Run `terraform init` to initialize the working directory.    
3. Run `terraform apply` to create the resources.
4. Locate the `terraform.tfstate` file in your working directory.
5. Open the `terraform.tfstate` file in a text editor and examine its contents.

**Note**: Never manually edit this file unless absolutely necessary and you know what you're doing.

### Task 2: Use terraform show

1. Run `terraform show` in your terminal.

2. Compare the output with the contents of the `terraform.tfstate` file.

3. Notice how `terraform show` presents the state information in a more readable format.


### Task 3: List Resources in the State

1. Run `terraform state list` in your terminal.

2. Observe the list of resources currently managed by Terraform.

   ```
   local_file.example_map["file1.txt"]
   local_file.example_map["file2.txt"]
   local_file.example_map["file3.txt"]
   ```

### Task 4: Show a Specific Resource

1. Choose one of the resources from the previous task's output.

2. Run `terraform state show <resource_name>` (e.g., `terraform state show 'local_file.example_map["file1.txt"]'`).


3. Examine the detailed information about the specific resource.

```
# local_file.example_map["file1.txt"]:
resource "local_file" "example_map" {
    content              = "This is the content of file 1"
    content_base64sha256 = "tYMOOdFNkzTKXXQKTFkDq0LppUJdhqZZFkBvYMm3HBY="
    content_base64sha512 = "Q8FVAkrRmJDGMvLWYGJBtTXZGcPZTKGW2ZGQbNUZGXlGXXKGtPqZBqGXWlNtsg7pJgagZqJ4YK1lfXSc6Xq9Aw=="
    content_md5          = "9d8783e3a801b1b1c9584d5f93f4b9b7"
    content_sha1         = "3f786850e387550fdab836ed7e6dc881de23001b"
    content_sha256       = "b5830e39d14d9334ca5d740a4c5903ab42e9a5425d86a6591640ef609b71c162"
    content_sha512       = "43c155024ad198908632f2d6606241b535d919c3d94ca196d991906cd519197946
```

### Task 5: Remove a Resource from State

1. Choose a resource to remove from the state (but not from the actual infrastructure).
2. Run `terraform state rm <resource_name>` (e.g., `terraform state rm 'local_file.example_map["file2.txt"]'`).
3. Run `terraform state list` again to verify the resource has been removed from the state.
4. Run `terraform plan` and observe that Terraform now wants to recreate the removed resource.

### Task 6: Move a Resource in State

1. Add a new resource block to your `main.tf`:
   ```hcl
   resource "local_file" "moved_file" {
     content  = "This file will be moved in state"
     filename = "${path.module}/${var.environment}_moved_file.txt"
   }
   ```
2. Run `terraform apply` to create the new resource.
3. Run `terraform state mv local_file.moved_file local_file.new_name`.
4. Update the resource name in your `main.tf` to match the new name:
   ```hcl
   resource "local_file" "new_name" {
     content  = "This file will be moved in state"
     filename = "${path.module}/${var.environment}_moved_file.txt"
   }
   ```
5. Run `terraform plan` to verify that no changes are needed.


### Task 7: Refresh State

1. Manually modify one of the created files (e.g., `dev_file1.txt`) without changing the `main.tf`.
2. Run `terraform refresh`.
3. Run `terraform show` and observe that the state has been updated to reflect the manual change.
4. Run `terraform plan` to see that Terraform detects the drift and wants to revert the manual change.
```
Terraform will perform the following actions:

    # local_file.example_map["file1.txt"] will be updated in-place
    ~ resource "local_file" "example_map" {
        id                   = "3f786850e387550fdab836ed7e6dc881de23001b"
    ~ content              = "Modified content" -> "This is the content of file 1"
    ~ content_base64sha256 = "tYMOOdFNkzTKXXQKTFkDq0LppUJdhqZZFkBvYMm3HBY=" -> "..."
    ~ content_base64sha512 = "Q8FVAkrRmJDGMvLWYGJBtTXZGcPZTKGW2ZGQbNUZGXlGXXKGtPqZBqGXWlNtsg7pJgagZqJ4YK1lfXSc6Xq9Aw==" -> "..."
    ~ content_md5          = "9d8783e3a801b1b1c9584d5f93f4b9b7" -> "..."
    ~ content_sha1         = "3f786850e387550fdab836ed7e6dc881de23001b" -> "..."
    ~ content_sha256       = "b5830e39d14d9334ca5d740a4c5903ab42e9a5425d86a6591640ef609b71c162" -> "..."
    ~ content_sha512       = "43c155024ad198908632f2d6606241b535d919c3d94ca196d991906cd519197946" -> "..."
        # (2 unchanged attributes hidden)
    }

Plan: 0 to add, 1 to change, 0 to destroy.
```
