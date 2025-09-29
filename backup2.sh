#!/usr/bin/env bash
set -euo pipefail

ENV_FILE="${1:-/home/deploy/whazing/backend/.env}"
CONTAINER_NAME="${CONTAINER_NAME:-postgresql}"
OUTFILE="$(pwd)/backupwhazing.sql.gz"

log() { echo "[ $(date '+%Y-%m-%d %H:%M:%S') ] $*"; }

if [[ ! -f "$ENV_FILE" ]]; then
  echo "ERRO: arquivo .env não encontrado em: $ENV_FILE" >&2
  exit 2
fi

# lê env
while IFS= read -r line; do
  [[ -z "$line" || "${line:0:1}" == "#" ]] && continue
  if echo "$line" | grep -Eq '^[A-Za-z_][A-Za-z0-9_]*='; then
    key="$(echo "$line" | cut -d= -f1)"
    val="$(echo "$line" | cut -d= -f2- | sed -e 's/^["'\'' ]*//' -e 's/["'\'' ]*$//')"
    case "$key" in
      DB_DIALECT) DB_DIALECT="$val" ;;
      POSTGRES_USER) POSTGRES_USER="$val" ;;
      POSTGRES_PASSWORD) POSTGRES_PASSWORD="$val" ;;
      POSTGRES_DB) POSTGRES_DB="$val" ;;
    esac
  fi
done < "$ENV_FILE"

if [[ "${DB_DIALECT:-}" != "postgres" ]]; then
  echo "ERRO: DB_DIALECT não é postgres (valor: ${DB_DIALECT:-unset})"
  exit 3
fi

log "Gerando backup no arquivo: $OUTFILE"

docker exec -e PGPASSWORD="$POSTGRES_PASSWORD" "$CONTAINER_NAME" \
  pg_dump -U "$POSTGRES_USER" "$POSTGRES_DB" \
  | gzip > "$OUTFILE"

chmod 600 "$OUTFILE"

log "Backup concluído com sucesso."
