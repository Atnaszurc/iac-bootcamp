variable "file_contents" {
description = "Map of file names and their contents"
type        = map(string)
default     = {
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