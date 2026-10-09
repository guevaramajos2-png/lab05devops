output "bucket_name" {
  description = "Nombre simulado del bucket"
  value       = local.bucket_name
}

output "artifact_files" {
  description = "Rutas de los artefactos generados"
  value       = local_file.artifact[*].filename
}
