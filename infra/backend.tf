# =============================================================================
# REMOTE STATE con locking (Bloque A del módulo)
# =============================================================================
# El state vive en S3 (versionado y cifrado) y el lock en DynamoDB, evitando
# que dos 'apply' simultáneos corrompan el estado.
#
# IMPORTANTE: el bucket y la tabla deben existir ANTES del primer init.
# El script aws/setup-backend.sh los crea.
#
# Reemplaza <ORG> por tu organización antes de usar.
# =============================================================================
terraform {
  backend "s3" {
    bucket         = "ORG-tfstate-m5"
    key            = "infra/produccion/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks-m5"
    encrypt        = true
  }
}
