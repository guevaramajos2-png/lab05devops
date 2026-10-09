terraform {
  required_version = ">= 1.5.0"
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
  # Backend local: el state queda en este directorio. En la variante sandbox no
  # usamos S3/DynamoDB porque no hay cuenta cloud. El flujo de PR/plan/apply es
  # idéntico; lo único que cambia es dónde vive el state.
}
