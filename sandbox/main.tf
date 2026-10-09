# =============================================================================
# VARIANTE SANDBOX — sin cuenta cloud
# =============================================================================
# Emula el módulo de artefactos usando providers locales. Sirve para ejercitar
# el flujo completo del módulo (plan en PR, apply con aprobación, drift) sin
# crear recursos reales ni necesitar credenciales.
#
# Para provocar DRIFT en el Lab 3: borra o edita a mano un archivo de
# generated/ y vuelve a correr 'terraform plan -detailed-exitcode'.
# =============================================================================

resource "random_id" "suffix" {
  byte_length = 4
}

locals {
  bucket_name = "${var.artifact_prefix}-${random_id.suffix.hex}"

  all_tags = merge(var.tags, {
    environment = var.environment
  })
}

resource "local_file" "artifact" {
  count    = var.artifact_count
  filename = "${path.module}/generated/${local.bucket_name}-${count.index}.txt"
  content  = "Artefacto ${count.index} del bucket ${local.bucket_name}\n"
}

resource "local_file" "metadata" {
  filename = "${path.module}/generated/${local.bucket_name}-metadata.json"
  content = jsonencode({
    bucket_name = local.bucket_name
    versioning  = "enabled"
    tags        = local.all_tags
    artifacts   = var.artifact_count
  })
}
