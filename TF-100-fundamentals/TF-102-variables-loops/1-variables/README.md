# Variables in Terraform

Objective: Learn how to use variables to make your Terraform configurations more flexible and reusable.

## Table of Contents

1. [Instructions](#instructions)
2. [Task 1: Copy the code from the previous block](#task-1-copy-the-code-from-the-previous-block)
3. [Task 2: Add a variables.tf file](#task-2-add-a-variables.tf-file)
4. [Task 3: Update the main.tf file to use variables](#task-3-update-the-main.tf-file-to-use-variables)
5. [Task 4: Create a terraform.tfvars file](#task-4-create-a-terraform.tfvars-file)
6. [Task 5: Initialize the working directory](#task-5-initialize-the-working-directory)
7. [Task 6: Plan the execution](#task-6-plan-the-execution)
8. [Task 7: Apply the execution plan](#task-7-apply-the-execution-plan)
9. [Task 8: Override the default value of file1_name](#task-8-override-the-default-value-of-file1_name)
10. [Task 9: Destroy the local files](#task-9-destroy-the-local-files)
11. [Explanation](#explanation)

## Instructions:

### Task 1. Copy the code from the previous block
Use the code from your previous block, or use the code from the example folder.

### Task 2. Add a variables.tf file
Create a new file called variables.tf and add the following code:
```hcl
variable "file1_content" {
  description = "Content for the first file"
  type        = string
  default     = "Hello, Terraform!"
}

variable "file2_content" {
  description = "Content for the second file"
  type        = string
  default     = "This is another file created by Terraform."
}

variable "file1_name" {
  description = "Name for the first file"
  type        = string
  default     = "hello.txt"
}

variable "file2_name" {
  description = "Name for the second file"
  type        = string
  default     = "another_file.txt"
}
```

### Task 3. Update the main.tf file to use variables
Change the main.tf file to use the variables instead of the hardcoded values by replacing the content and filename in the local_file resource blocks with the following code:
```hcl
resource "local_file" "example1" {
  content  = var.file1_content
  filename = "${path.module}/${var.file1_name}"
}

resource "local_file" "example2" {
  content  = var.file2_content
  filename = "${path.module}/${var.file2_name}"
}
```

### Task 4. Create a terraform.tfvars file
Create a file named terraform.tfvars in the same directory with the following content:
```hcl
file1_content = "This is the content for file 1 from tfvars."
file2_content = "This is the content for file 2 from tfvars."
file1_name    = "file1.txt"
file2_name    = "file2.txt"
```

### Task 5. Initialize the working directory
Run `terraform init` to initialize the working directory.

### Task 6. Plan the execution
Run `terraform plan` to see what changes will be made.

### Task 7. Apply the execution plan
Run `terraform apply` to create the local files.

### Task 8. Override the default value of file1_name
Run `terraform plan -var "file1_name=test.txt"` to see what changes will be made.

### Task 9. Destroy the local files
Once you are done, run `terraform destroy` to destroy the local files.

## Explanation: 

This configuration does the following:
1. It defines four variables: file1_content, file2_content, file1_name, and file2_name.
2. Each variable has a description, type, and default value.
3. The local_file resources use these variables for their content and filenames.
4. The terraform.tfvars file provides custom values for these variables.
5. The -var flag is used to override the default value of file1_name as well as the value from the terraform.tfvars file.

After running terraform apply, you should see two new files in your project directory:
- file1.txt with the content "This is the content for file 1 from tfvars."
- file2.txt with the content "This is the content for file 2 from tfvars."

This example demonstrates how to use variables in Terraform:
1. Variables are defined in the main configuration file.
2. Default values are provided, but can be overridden.
3. The terraform.tfvars file is used to set custom values for the variables.
4. Variables are referenced in the resource definitions using the var. prefix.