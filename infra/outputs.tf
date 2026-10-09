output "bucket_id" {
  description = "Bucket de artefactos creado"
  value       = module.artifacts.bucket_id
}

output "bucket_arn" {
  description = "ARN del bucket de artefactos"
  value       = module.artifacts.bucket_arn
}
