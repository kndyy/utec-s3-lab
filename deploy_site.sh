#!/usr/bin/env bash
# Despliega una carpeta como sitio estatico en S3.
# Uso: ./deploy_site.sh <bucket> <carpeta> [region]
set -euo pipefail

BUCKET="${1:?Uso: $0 <bucket> <carpeta> [region]}"
SRC="${2:?Uso: $0 <bucket> <carpeta> [region]}"
REGION="${3:-$(aws configure get region --profile "${AWS_PROFILE:-leonardo-utec}")}"

[[ -d "$SRC" ]] || { echo "La carpeta '$SRC' no existe"; exit 3; }
aws sts get-caller-identity >/dev/null || { echo "No autenticado. Ejecuta aws configure"; exit 2; }

if aws s3api head-bucket --bucket "$BUCKET" >/dev/null 2>&1; then
  echo "Bucket $BUCKET ya existe, reutilizando"
else
  echo "Creando bucket $BUCKET en $REGION"
  aws s3 mb "s3://$BUCKET" --region "$REGION"
fi

echo "Configurando acceso publico"
aws s3api put-public-access-block --bucket "$BUCKET" \
  --public-access-block-configuration \
  "BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false"

aws s3api put-bucket-policy --bucket "$BUCKET" --policy "$(cat <<JSON
{"Version":"2012-10-17","Statement":[{"Sid":"PublicReadGetObject","Effect":"Allow",
"Principal":"*","Action":"s3:GetObject","Resource":"arn:aws:s3:::$BUCKET/*"}]}
JSON
)"

echo "Sincronizando $SRC"
aws s3 sync "$SRC/" "s3://$BUCKET/" --delete

aws s3 website "s3://$BUCKET/" --index-document index.html --error-document error.html

SITE_URL="${SITE_URL_OVERRIDE:-http://$BUCKET.s3-website-$REGION.amazonaws.com}"
printf '\nSitio desplegado: %s\n' "$SITE_URL"
curl -s -o /dev/null -w "   HTTP %{http_code}\n" "$SITE_URL"
