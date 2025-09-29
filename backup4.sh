#!/usr/bin/env bash
set -euo pipefail

# Caminho padrão para o .env se não passar argumento
ENV_FILE="${1:-/home/deploy/whazing/backend/.env}"

# Nome do container do Postgres (mude se não for "postgresql")
CONTAINER_NAME="${CONTAINER_NAME:-postgresql}"

# Nome fixo do arquivo de backup (na pasta atual)
OUTFILE="$(pwd)/backupwhazing.sql.gz"

log() { echo "[ $(date '+%Y-%m-%d %H:%M:%S') ] $*"; }

if [[ ! -f "$ENV_FILE" ]]; then
  echo "ERRO: arquivo .env não encontrado em: $ENV_FILE" >&2
  exit 2
fi

# Lê variáveis do .env
while IFS= read -r line; do
  [[ -z "$line" || "${line:0:1}" == "#" ]] && continue
  if echo "$line" | grep -Eq '^[A-Za-z_][A-Za-z0-9_]*='; then
    key="$(echo "$line" | cut -d= -f1)"
    val="$(echo "$line" | cut -d= -f2- | sed -e 's/^["'\'' ]*//' -e 's/["'\'' ]*$//')"
    case "$key" in
      POSTGRES_USER) POSTGRES_USER="$val" ;;
      POSTGRES_PASSWORD) POSTGRES_PASSWORD="$val" ;;
      POSTGRES_DB) POSTGRES_DB="$val" ;;
      POSTGRES_HOST) POSTGRES_HOST="$val" ;;
      POSTGRES_PORT|DB_PORT) POSTGRES_PORT="$val" ;;
    esac
  fi
done < "$ENV_FILE"

# Valores padrão
POSTGRES_HOST="${POSTGRES_HOST:-localhost}"
POSTGRES_PORT="${POSTGRES_PORT:-5432}"

# Executa o backup
log "Gerando backup no arquivo: $OUTFILE"

docker exec -e PGPASSWORD="$POSTGRES_PASSWORD" "$CONTAINER_NAME" \
  pg_dump -U "$POSTGRES_USER" -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" "$POSTGRES_DB" \
  | gzip > "$OUTFILE"

chmod 600 "$OUTFILE"

log "Backup concluído com sucesso."
