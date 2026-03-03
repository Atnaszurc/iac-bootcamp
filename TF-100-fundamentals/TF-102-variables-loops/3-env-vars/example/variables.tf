variable "file_contents" {
  description = "List of contents for files"
  type        = list(string)
  default     = ["Content 1", "Content 2", "Content 3"]
}

variable "file_names" {
  description = "Map of file names and their contents"
  type        = map(string)
  default = {
    "file_a.txt" = "Content for file A"
    "file_b.txt" = "Content for file B"
    "file_c.txt" = "Content for file C"
  }
}