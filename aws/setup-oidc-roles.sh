#!/usr/bin/env bash
# =============================================================================
# Crea el IAM OIDC provider y los DOS roles del módulo:
#   - tf-plan-m5   : SOLO LECTURA. Lo usan los workflows de plan y de drift.
#   - tf-apply-m5  : ESCRITURA. Solo desde la rama main. Lo usa el workflow de apply.
#
# La separación de roles es el aprendizaje de seguridad central del módulo:
# el plan no necesita permisos de escritura, así que dárselos violaría el
# principio de menor privilegio.
#
# Se ejecuta UNA vez, en local, con credenciales de admin de la cuenta SANDBOX.
#
# Uso:
#   export ACCOUNT_ID=123456789012
#   export GH_ORG=mi-org
#   export ORG=mi-org          # mismo valor usado en setup-backend.sh
#   ./setup-oidc-roles.sh
# =============================================================================
set -euo pipefail

: "${ACCOUNT_ID:?Define ACCOUNT_ID (12 digitos)}"
: "${GH_ORG:?Define GH_ORG (tu organizacion de GitHub)}"
: "${ORG:?Define ORG (prefijo usado en el bucket de state)}"
REPO="iac-github"

echo "==> 1. Creando el IAM OIDC provider (idempotente)"
if ! aws iam list-open-id-connect-providers | grep -q "token.actions.githubusercontent.com"; then
  aws iam create-open-id-connect-provider \
    --url "https://token.actions.githubusercontent.com" \
    --client-id-list "sts.amazonaws.com" \
    --thumbprint-list "ffffffffffffffffffffffffffffffffffffffff"
  echo "    Provider creado."
else
  echo "    Ya existe; se omite."
fi

# Función que renderiza los placeholders y crea/actualiza un rol
crear_rol () {
  local ROLE_NAME="$1"
  local TRUST_FILE="$2"
  local PERMS_FILE="$3"
  local POLICY_NAME="$4"

  echo "==> Creando rol ${ROLE_NAME}"

  sed -e "s/<ACCOUNT_ID>/${ACCOUNT_ID}/g" \
      -e "s#<TU-ORG>/iac-github#${GH_ORG}/${REPO}#g" \
      "${TRUST_FILE}" > "/tmp/${ROLE_NAME}-trust.json"

  sed "s/ORG-tfstate-m5/${ORG}-tfstate-m5/g" \
      "${PERMS_FILE}" > "/tmp/${ROLE_NAME}-perms.json"

  echo "--- trust policy de ${ROLE_NAME} ---"
  cat "/tmp/${ROLE_NAME}-trust.json"

  aws iam create-role \
    --role-name "${ROLE_NAME}" \
    --assume-role-policy-document "file:///tmp/${ROLE_NAME}-trust.json" \
    >/dev/null 2>&1 \
  || aws iam update-assume-role-policy \
       --role-name "${ROLE_NAME}" \
       --policy-document "file:///tmp/${ROLE_NAME}-trust.json"

  aws iam put-role-policy \
    --role-name "${ROLE_NAME}" \
    --policy-name "${POLICY_NAME}" \
    --policy-document "file:///tmp/${ROLE_NAME}-perms.json"

  echo "    Rol listo: arn:aws:iam::${ACCOUNT_ID}:role/${ROLE_NAME}"
  echo ""
}

crear_rol "tf-plan-m5"  "trust-policy-plan.json"  "permissions-plan.json"  "tf-plan-readonly"
crear_rol "tf-apply-m5" "trust-policy-apply.json" "permissions-apply.json" "tf-apply-write"

echo "LISTO. ARNs para usar en los workflows:"
echo "  plan  : arn:aws:iam::${ACCOUNT_ID}:role/tf-plan-m5"
echo "  apply : arn:aws:iam::${ACCOUNT_ID}:role/tf-apply-m5"
echo ""
echo "Recuerda: el rol de plan acepta cualquier rama (solo lee);"
echo "el de apply SOLO acepta refs/heads/main (escribe de verdad)."
