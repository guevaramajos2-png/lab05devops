#!/usr/bin/env bash
# =============================================================================
# Crea el backend remoto de Terraform: bucket S3 (state) + tabla DynamoDB (lock).
# Se ejecuta UNA vez, en local, con credenciales de administrador de la cuenta
# SANDBOX. El workflow NO usa estas credenciales (usa OIDC).
#
# Uso:
#   export ORG=mi-org
#   export REGION=us-east-1
#   ./setup-backend.sh
# =============================================================================
set -euo pipefail

: "${ORG:?Define ORG (tu organizacion, en minusculas)}"
: "${REGION:=us-east-1}"

BUCKET="${ORG}-tfstate-m5"
TABLE="terraform-locks-m5"

echo "==> 1. Creando el bucket de state: ${BUCKET}"
if aws s3api head-bucket --bucket "${BUCKET}" 2>/dev/null; then
  echo "    Ya existe; se omite."
else
  if [ "${REGION}" = "us-east-1" ]; then
    aws s3api create-bucket --bucket "${BUCKET}" --region "${REGION}"
  else
    aws s3api create-bucket --bucket "${BUCKET}" --region "${REGION}" \
      --create-bucket-configuration "LocationConstraint=${REGION}"
  fi
fi

echo "==> 2. Habilitando versionado del state (permite recuperar versiones previas)"
aws s3api put-bucket-versioning \
  --bucket "${BUCKET}" \
  --versioning-configuration Status=Enabled

echo "==> 3. Habilitando cifrado en reposo (el state puede contener datos sensibles)"
aws s3api put-bucket-encryption \
  --bucket "${BUCKET}" \
  --server-side-encryption-configuration \
  '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

echo "==> 4. Bloqueando acceso público al bucket de state"
aws s3api put-public-access-block \
  --bucket "${BUCKET}" \
  --public-access-block-configuration \
  "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

echo "==> 5. Creando la tabla de locks: ${TABLE}"
if aws dynamodb describe-table --table-name "${TABLE}" --region "${REGION}" >/dev/null 2>&1; then
  echo "    Ya existe; se omite."
else
  aws dynamodb create-table \
    --table-name "${TABLE}" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region "${REGION}"
  echo "    Esperando a que la tabla esté activa..."
  aws dynamodb wait table-exists --table-name "${TABLE}" --region "${REGION}"
fi

echo ""
echo "LISTO. Actualiza infra/backend.tf con estos valores:"
echo "  bucket         = \"${BUCKET}\""
echo "  dynamodb_table = \"${TABLE}\""
echo "  region         = \"${REGION}\""
