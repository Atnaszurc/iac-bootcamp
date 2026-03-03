output "created_files" {
value = [for file in local_file.example_map : file.filename]
}