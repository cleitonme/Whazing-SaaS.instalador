#!/bin/bash

ENV_FILE="/home/deploy/whazing/backend/.env"
CONTAINER_NAME="postgresql"
BACKEND_CONTAINER="whazing-backend"
BACKUP_FILE="/home/deploy/backupwhazing.sql.gz"
TEMP_SQL="/home/deploy/backupwhazing.sql"

# Aviso grande
echo "############################################################"
echo "ATENÇÃO! Este script irá RESTAURAR o banco de dados."
echo "Ele irá parar o backend, criar um novo banco, restaurar o backup e alterar o .env."
echo "Se você NÃO tiver certeza, pressione CTRL+C para cancelar."
echo "Iniciando em 60 segundos..."
echo "############################################################"
sleep 60

# Remove caracteres Windows (se existirem)
sed -i 's/\r$//' "$ENV_FILE" 2>/dev/null || true

# Carrega variáveis do .env
if [[ ! -f "$ENV_FILE" ]]; then
  echo "ERRO: arquivo .env não encontrado em: $ENV_FILE" >&2
  exit 2
fi

echo "[INFO] Carregando variáveis do .env..."
set -a
source "$ENV_FILE" || {
  echo "ERRO: Falha ao carregar .env. Verifique a sintaxe do arquivo." >&2
  exit 4
}
set +a

# Verifica se as variáveis necessárias foram carregadas
if [[ -z "${POSTGRES_USER:-}" ]] || [[ -z "${POSTGRES_DB:-}" ]]; then
  echo "ERRO: POSTGRES_USER ou POSTGRES_DB não definidos no .env" >&2
  exit 5
fi

echo "[INFO] Variáveis carregadas: POSTGRES_USER=$POSTGRES_USER, POSTGRES_DB=$POSTGRES_DB"

# Verifica backup ANTES de ativar set -e
echo "[INFO] Verificando arquivo de backup em: $BACKUP_FILE"
if [[ ! -f "$BACKUP_FILE" ]]; then
  echo "ERRO: arquivo de backup não encontrado em: $BACKUP_FILE" >&2
  echo "[INFO] Arquivos .sql.gz disponíveis no diretório:" >&2
  ls -lh /home/deploy/*.sql.gz 2>/dev/null || echo "Nenhum arquivo .sql.gz encontrado" >&2
  exit 3
fi
echo "[INFO] Backup encontrado: $(ls -lh "$BACKUP_FILE")"

# Ativa modo strict APÓS todas as verificações
set -euo pipefail

# Para o backend
echo "[INFO] Parando backend..."
docker container stop "$BACKEND_CONTAINER"

# Nome do novo banco
NEW_DB="${POSTGRES_DB}_restore_$(date '+%Y%m%d%H%M%S')"
echo "[INFO] Criando novo banco: $NEW_DB"
docker exec -i "$CONTAINER_NAME" psql -U "$POSTGRES_USER" -c "CREATE DATABASE \"$NEW_DB\";"
echo "[INFO] Banco criado com sucesso!"

# Descompacta backup
echo "[INFO] Descompactando backup..."
gunzip -c "$BACKUP_FILE" > "$TEMP_SQL"
echo "[INFO] Backup descompactado. Tamanho: $(ls -lh "$TEMP_SQL" | awk '{print $5}')"

# Restaura dentro do container
echo "[INFO] Restaurando backup no banco $NEW_DB..."
cat "$TEMP_SQL" | docker exec -i "$CONTAINER_NAME" psql -U "$POSTGRES_USER" -d "$NEW_DB"
echo "[INFO] Backup restaurado com sucesso!"

# Apaga arquivo temporário
echo "[INFO] Removendo arquivo temporário..."
rm -f "$TEMP_SQL"

# Atualiza .env
echo "[INFO] Atualizando .env para usar o novo banco..."
if grep -q '^POSTGRES_DB=' "$ENV_FILE"; then
  sed -i "s/^POSTGRES_DB=.*/POSTGRES_DB=$NEW_DB/" "$ENV_FILE"
else
  echo "POSTGRES_DB=$NEW_DB" >> "$ENV_FILE"
fi
echo "[INFO] .env atualizado!"

# Inicia backend
echo "[INFO] Iniciando backend..."
docker container start "$BACKEND_CONTAINER"

echo ""
echo "############################################################"
echo "[SUCESSO] Restauração concluída!"
echo "Novo banco: $NEW_DB"
echo "Backend reiniciado"
echo "############################################################"