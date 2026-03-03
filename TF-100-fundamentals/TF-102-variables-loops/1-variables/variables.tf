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
