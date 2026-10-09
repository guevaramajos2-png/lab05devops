# Scripts de setup de AWS

Se ejecutan **una sola vez**, en local, con credenciales de administrador de la
cuenta sandbox. **Los workflows no usan estas credenciales**: usan OIDC.

## Orden de ejecución

```bash
# 1. Backend remoto (state + lock)
export ORG=mi-org
export REGION=us-east-1
./setup-backend.sh

# 2. Provider OIDC + los dos roles
export ACCOUNT_ID=123456789012
export GH_ORG=mi-org
./setup-oidc-roles.sh
```

## Qué crea cada script

**`setup-backend.sh`**
- Bucket S3 `<ORG>-tfstate-m5` con versionado, cifrado AES256 y acceso público bloqueado.
- Tabla DynamoDB `terraform-locks-m5` (clave `LockID`) para el state locking.

**`setup-oidc-roles.sh`**
- El IAM OIDC provider para `token.actions.githubusercontent.com`.
- **`tf-plan-m5`** — solo lectura. Trust policy: acepta cualquier rama del repo
  (`repo:ORG/iac-github:*`), porque un plan no modifica nada.
- **`tf-apply-m5`** — escritura. Trust policy: **solo** `refs/heads/main`.

## Los archivos de policy

| Archivo | Para qué |
|---------|----------|
| `trust-policy-plan.json` | Quién puede asumir el rol de plan (cualquier rama) |
| `trust-policy-apply.json` | Quién puede asumir el rol de apply (solo main) |
| `permissions-plan.json` | Qué puede hacer el plan: leer state, lock, y leer recursos |
| `permissions-apply.json` | Qué puede hacer el apply: escribir state y gestionar buckets |

Los placeholders `<ACCOUNT_ID>`, `<TU-ORG>` y `ORG-tfstate-m5` los sustituye el
script automáticamente a partir de tus variables de entorno.

## Limpieza al terminar

```bash
aws iam delete-role-policy --role-name tf-plan-m5  --policy-name tf-plan-readonly
aws iam delete-role-policy --role-name tf-apply-m5 --policy-name tf-apply-write
aws iam delete-role --role-name tf-plan-m5
aws iam delete-role --role-name tf-apply-m5
aws dynamodb delete-table --table-name terraform-locks-m5
# El bucket de state requiere vaciar las versiones antes de borrarlo.
```
