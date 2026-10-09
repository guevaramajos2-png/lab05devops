variable "artifact_prefix" {
  description = "Prefijo del 'bucket' simulado"
  type        = string
  default     = "artifacts"
}

variable "artifact_count" {
  description = "Número de artefactos simulados"
  type        = number
  default     = 3
}

variable "environment" {
  description = "Nombre del entorno"
  type        = string
  default     = "sandbox"
}

variable "tags" {
  description = "Etiquetas comunes"
  type        = map(string)
  default = {
    managed_by = "terraform"
  }
}
