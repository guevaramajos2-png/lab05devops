variable "bucket_name" {
  description = "Nombre del bucket de artefactos"
  type        = string
}

variable "enable_versioning" {
  description = "Habilitar versionado de objetos"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Etiquetas comunes aplicadas a los recursos"
  type        = map(string)
  default     = {}
}

variable "transition_days" {
  description = "Días tras los que los objetos pasan a GLACIER"
  type        = number
  default     = 90
}
