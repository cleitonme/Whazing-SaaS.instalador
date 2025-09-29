#!/bin/bash
set -euo pipefail

ENV_FILE="/home/deploy/whazing/backend/.env"
sed -i 's/\r$//' "$ENV_FILE"

CONTAINER_NAME="postgresql"
BACKEND_CONTAINER="whazing-backend"
BACKUP_FILE="$(pwd)/backupwhazing.sql.gz"

# Aviso grande
echo "############################################################"
echo "ATENÇÃO! Este script irá RESTAURAR o banco de dados."
echo "Ele irá parar o backend, criar um novo banco, restaurar o backup e alterar o .env."
echo "Se você NÃO tiver certeza, pressione CTRL+C para cancelar."
echo "Iniciando em 60 segundos..."
echo "############################################################"
sleep 60

# Carrega variáveis do .env
if [[ ! -f "$ENV_FILE" ]]; then
  echo "ERRO: arquivo .env não encontrado em: $ENV_FILE" >&2
  exit 2
fi

set -a
source "$ENV_FILE"
set +a

# Verifica backup
if [[ ! -f "$BACKUP_FILE" ]]; then
  echo "ERRO: arquivo de backup não encontrado em: $BACKUP_FILE" >&2
  exit 3
fi

# Para o backend
echo "[INFO] Parando backend..."
docker container stop "$BACKEND_CONTAINER"

# Nome do novo banco
NEW_DB="${POSTGRES_DB}_restore_$(date '+%Y%m%d%H%M%S')"
echo "[INFO] Criando novo banco: $NEW_DB"

docker exec -i "$CONTAINER_NAME" /bin/bash -c \
  "PGPASSWORD=$POSTGRES_PASSWORD psql -U $POSTGRES_USER -c \"CREATE DATABASE $NEW_DB;\""

# Restaura o backup
echo "[INFO] Restaurando backup..."
gzip -dc "$BACKUP_FILE" | docker exec -i "$CONTAINER_NAME" psql -U "$POSTGRES_USER" -d "$NEW_DB"

# Atualiza .env
echo "[INFO] Atualizando .env para usar o novo banco..."
# Remove a linha antiga e adiciona a nova
if grep -q '^POSTGRES_DB=' "$ENV_FILE"; then
  sed -i "s/^POSTGRES_DB=.*/POSTGRES_DB=$NEW_DB/" "$ENV_FILE"
else
  echo "POSTGRES_DB=$NEW_DB" >> "$ENV_FILE"
fi

# Inicia backend
echo "[INFO] Iniciando backend..."
docker container start "$BACKEND_CONTAINER"

echo "[SUCESSO] Restauração concluída! Novo banco: $NEW_DB"
