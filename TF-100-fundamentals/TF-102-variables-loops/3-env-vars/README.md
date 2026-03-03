# Using Variables and Environment Variables in Terraform

Objective: Learn how to use different types of variables, including environment variables, in Terraform configurations.

## Table of Contents

1. [Instructions](#instructions)
2. [Task 1-modify the file_contents variable to use a map](#task-1-modify-the-file_contents-variable-to-use-a-map)
3. [Task 2-update the resource using the new map](#task-2-update-the-resource-using-the-new-map)
4. [Task 3-add a new variable for file extension](#task-3-add-a-new-variable-for-file-extension)
5. [Task 4-use an environment variable](#task-4-use-an-environment-variable)
6. [Task 5-use the environment variable in your resource](#task-5-use-the-environment-variable-in-your-resource)
7. [Task 6-add an outputs.tf file with the following content](#task-6-add-an-outputs.tf-file-with-the-following-content)
8. [Task 7-run terraform commands](#task-7-run-terraform-commands)
9. [Additional exercises](#additional-exercises)
10. [Gotchas and tips for beginners](#gotchas-and-tips-for-beginners)


## Instructions

### Task 1: Modify the file_contents variable to use a map
Change the file_contents variable from a list to a map. Here's how:
```
variable "file_contents" {
  description = "Map of file names and their contents"
  type        = map(string)
  default     = {
    "file1.txt" = "This is the content of file 1"
    "file2.txt" = "Here's the content for file 2"
    "file3.txt" = "File 3 content goes here"
  }
}
```

### Task 2: Update the resource using the new map
Modify the local_file.example_count resource to use the new map:

```
resource "local_file" "example_map" {
  for_each = var.file_contents
  content  = each.value
  filename = "${path.module}/${each.key}"
}
```

### Task 3: Add a new variable for file extension
```
variable "file_extension" {
  description = "File extension for created files"
  type        = string
  default     = "txt"
}
```

### Task 4: Use an environment variable
First, set an environment variable in your terminal:
For Linux/macOS:
`export TF_VAR_environment=dev`
For Windows:
`set TF_VAR_environment=dev`

Then, add this variable to your Terraform configuration:
```
variable "environment" {
  description = "Deployment environment"
  type        = string
}
```

### Task 5: Use the environment variable in your resource
Modify the local_file.example_map resource to use the environment variable:
```
resource "local_file" "example_map" {
  for_each = var.file_contents
  content  = each.value
  filename = "${path.module}/${var.environment}_${each.key}"
}
```
### Task 6: Add an outputs.tf file with the following content:
```
output "created_files" {
  value = [for file in local_file.example_map : file.filename]
}
```

### Task 7: Run Terraform commands
Initialize Terraform:
`terraform init`
Plan the execution:
`terraform plan`
Apply the changes:
`terraform apply`

Check the working directory for the created files.

### Additional exercises

Notice that the files are not using the file extension from the file_extension variable.
See if you can fix it. Hint: it's part of the filename in the local_file resource.

Remember the tfvars file we created in the previous task?
Try to create a tfvars file for the files we created in this task, remember that we changed the file_contents variable to a map.

## Gotchas and tips for beginners:
1. Make sure to set the environment variable before running Terraform commands.
2. The `${path.module}` expression refers to the current directory.
3. In the `for_each` block, `each.key` refers to the map key (file name in this case), and `each.value` refers to the map value (file content).
4. The output uses a `for` expression to create a list of all created file names.
5. Always run terraform plan before `terraform apply` to review changes.
6. If you make a mistake, you can always run `terraform destroy` to remove all created resources and start over.

## Some ways to set variables in Terraform:
1. Terraform CLI
  - terraform plan -var 'file_extension=txt'
2. Environment variables
  - export TF_VAR_file_extension=txt
3. tfvars files
  - terraform.tfvars
  - terraform.tfvars.json
  - *.auto.tfvars
  - *.auto.tfvars.json
4. hardcoded inside the variables.tf file
