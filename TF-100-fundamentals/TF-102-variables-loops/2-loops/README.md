# Using Loops in Terraform for Efficient Resource Creation

Objective: Learn how to use different types of loops in Terraform to create multiple resources efficiently.

## Table of Contents

1. [Instructions](#instructions)
2. [Task 1: Copy the code from the previous block](#task-1-copy-the-code-from-the-previous-block)
3. [Task 2: Update the main.tf file](#task-2-update-the-main.tf-file)
4. [Task 3: Update the variables.tf file](#task-3-edit-variabletf)
5. [Task 4: Terraform.tfvars file edits](#task-4-terraform.tfvars-file-edits)
6. [Task 5: Terraform init](#task-5-terraform-init)
7. [Task 6: Terraform plan](#task-6-terraform-plan)
8. [Task 7: Terraform apply](#task-7-terraform-apply)
9. [Task 8: Terraform destroy](#task-8-terraform-destroy)

## Instructions:

In this block we will learn how to use loops in Terraform. We will use three methods: count, for_each with a map and for_each with a set.

### Task 1. Copy the code from the previous block
Use the code from your previous block, or use the code from the example folder.

### Task 2. Update the main.tf file
In the main.tf file, remove the old resource blocks and add the following code:
```hcl
# Using count
resource "local_file" "example_count" {
  count    = length(var.file_contents)
  content  = var.file_contents[count.index]
  filename = "${path.module}/count_file_${count.index + 1}.txt"
}

# Using for_each
resource "local_file" "example_for_each" {
  for_each = var.file_names
  content  = each.value
  filename = "${path.module}/${each.key}"
}

# Using for_each with a set
resource "local_file" "example_for_each_set" {
  for_each = toset(["apple", "banana", "cherry"])
  content  = "I like ${each.key}"
  filename = "${path.module}/fruit_${each.key}.txt"
}
```

### Task 3. Edit variable.tf
Edit the variables.tf file to look like this:
```hcl
variable "file_contents" {
  type = list(string)
}

variable "file_names" {
  type = map(string)
}
```

### Task 4. Terraform.tfvars file edits
If you kept your terraform.tfvars file, remove the previous content and add the following code:
```hcl
file_contents = [
  "This is the first file created using count.",
  "This is the second file created using count.",
  "This is the third file created using count.",
  "This is the fourth file created using count."
]

file_names = {
  "custom_a.txt" = "This is custom file A created using for_each."
  "custom_b.txt" = "This is custom file B created using for_each."
  "custom_c.txt" = "This is custom file C created using for_each."
  "custom_d.txt" = "This is custom file D created using for_each."
}
```

### Task 5. Terraform init
Run `terraform init` to initialize the working directory.

### Task 6. Terraform plan
Run `terraform plan` to see what changes will be made.

### Task 7. Terraform apply
Run `terraform apply` to create the local files.

This configuration demonstrates three ways of using loops in Terraform:
1. Using count:
  - We define a list variable file_contents.
  - The local_file.example_count resource uses count to create a file for each item in the list.
  - The filename includes the index, and the content is taken from the list.
2. Using for_each with a map:
  - We define a map variable file_names.
  - The local_file.example_for_each resource uses for_each to create a file for each key-value pair in the map.
  - The filename is the key, and the content is the value.
3. Using for_each with a set:
  - We use toset() to create a set of fruit names.
  - The local_file.example_for_each_set resource creates a file for each fruit in the set.
  - The filename includes the fruit name, and the content is a sentence using the fruit name.

After running `terraform apply`, you should see the following files in your project directory:
- count_file_1.txt, count_file_2.txt, count_file_3.txt, count_file_4.txt
- custom_a.txt, custom_b.txt, custom_c.txt, custom_d.txt
- fruit_apple.txt, fruit_banana.txt, fruit_cherry.txt

This example showcases how to use loops in Terraform to create multiple similar resources efficiently. The count parameter is useful when you have a list of items and want to create a resource for each one. The for_each meta-argument is more flexible and can be used with maps or sets, allowing you to create resources with unique names or properties for each item.

### Task 8. Terraform destroy

Once you are done, run `terraform destroy` to destroy the local files.

