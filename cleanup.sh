#!/usr/bin/env bash
# Elimina un bucket S3 y todo su contenido.
# Uso: ./cleanup.sh <bucket>
set -euo pipefail

BUCKET="${1:?Uso: $0 <bucket>}"

if ! aws s3api head-bucket --bucket "$BUCKET" >/dev/null 2>&1; then
  echo "El bucket $BUCKET no existe. Nada que limpiar."
  exit 0
fi

read -r -p "Se eliminara s3://$BUCKET y TODO su contenido. Continuar? (y/N): " ok
[[ "$ok" =~ ^[Yy]$ ]] || { echo "Cancelado"; exit 0; }

aws s3api delete-bucket-policy --bucket "$BUCKET" 2>/dev/null || true
aws s3 rm "s3://$BUCKET" --recursive
aws s3 rb "s3://$BUCKET"

echo "Bucket $BUCKET eliminado"
