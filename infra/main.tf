provider "aws" {
  region = var.aws_region
}

# Consume el módulo reutilizable. En un repo real el módulo viviría en su propio
# repositorio y se referenciaría por tag:
#   source = "git::https://github.com/ORG/modules.git//s3-artifacts?ref=v1.0.0"
module "artifacts" {
  source = "../modules/s3-artifacts"

  bucket_name       = var.bucket_name
  enable_versioning = true
  transition_days   = 90

  tags = {
    environment = var.environment
    managed_by  = "terraform"
    repo        = "iac-github"
  }
}
