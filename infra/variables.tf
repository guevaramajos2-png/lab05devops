variable "aws_region" {
  description = "Región de AWS"
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "Nombre del bucket de artefactos a crear"
  type        = string
}

variable "environment" {
  description = "Nombre del entorno"
  type        = string
  default     = "produccion"
}
