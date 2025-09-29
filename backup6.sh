#!/bin/bash
set -euo pipefail

# Caminho do .env
ENV_FILE="/home/deploy/whazing/backend/.env"

# Nome do container PostgreSQL
CONTAINER_NAME="postgresql"

# Arquivo de backup na pasta atual
BACKUP_FILE="$(pwd)/backupwhazing.sql.gz"

log() { echo "[ $(date '+%Y-%m-%d %H:%M:%S') ] $*"; }

if [[ ! -f "$ENV_FILE" ]]; then
  echo "ERRO: arquivo .env não encontrado em: $ENV_FILE" >&2
  exit 2
fi

# Carrega variáveis do .env
set -a
source "$ENV_FILE"
set +a

log "Gerando backup no arquivo: $BACKUP_FILE"

# Executa pg_dump dentro do container e compacta
docker exec -i "$CONTAINER_NAME" /bin/bash -c \
  "PGPASSWORD=$POSTGRES_PASSWORD pg_dump --username=$POSTGRES_USER --dbname=$POSTGRES_DB" \
  | gzip > "$BACKUP_FILE"

chmod 600 "$BACKUP_FILE"

log "Backup concluído com sucesso."
