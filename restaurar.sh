#!/bin/bash

# Função para capturar erros
trap 'echo "[ERRO] Falha na linha $LINENO. Comando: $BASH_COMMAND" >&2' ERR

# Detecta o diretório onde o script está sendo executado
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ENV_FILE="/home/deploy/whazing/backend/.env"
CONTAINER_NAME="postgresql"
BACKEND_CONTAINER="whazing-backend"
PGBOUNCER_CONTAINER="pgbouncer-whazing"
BACKUP_FILE="${SCRIPT_DIR}/backupwhazing.sql.gz"
TEMP_SQL="${SCRIPT_DIR}/backupwhazing.sql"

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
source "$ENV_FILE"
EXIT_CODE=$?
set +a

if [ $EXIT_CODE -ne 0 ]; then
  echo "ERRO: Falha ao carregar .env. Exit code: $EXIT_CODE" >&2
  exit 4
fi

# Verifica se as variáveis necessárias foram carregadas
if [[ -z "${POSTGRES_USER:-}" ]] || [[ -z "${POSTGRES_DB:-}" ]]; then
  echo "ERRO: POSTGRES_USER ou POSTGRES_DB não definidos no .env" >&2
  exit 5
fi

# DEBUG: Mostra todas as variáveis relacionadas ao PG
echo ""
echo "############################################################"
echo "[DEBUG] Variáveis do PostgreSQL carregadas:"
echo "  POSTGRES_USER: ${POSTGRES_USER}"
echo "  POSTGRES_DB: ${POSTGRES_DB}"
echo "  POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:+***SET***}"
echo "  DB_PORT: ${DB_PORT:-5432}"
echo "  DB_HOST: ${DB_HOST:-localhost}"
echo "############################################################"
echo ""

# Verifica POSTGRES_PASSWORD se estiver usando PgBouncer
if [[ "${DB_PORT:-5432}" == "6432" ]] && [[ -z "${POSTGRES_PASSWORD:-}" ]]; then
  echo "ERRO: POSTGRES_PASSWORD não definido no .env (necessário para PgBouncer)" >&2
  exit 12
fi

# Verifica backup
echo "[INFO] Verificando arquivo de backup em: $BACKUP_FILE"
if [[ ! -f "$BACKUP_FILE" ]]; then
  echo "ERRO: arquivo de backup não encontrado em: $BACKUP_FILE" >&2
  echo "[INFO] Arquivos .sql.gz disponíveis no diretório:" >&2
  ls -lh "${SCRIPT_DIR}"/*.sql.gz 2>/dev/null || echo "Nenhum arquivo .sql.gz encontrado" >&2
  exit 3
fi
echo "[INFO] Backup encontrado: $(ls -lh "$BACKUP_FILE")"

# Para o backend
echo "[INFO] Parando backend..."
docker container stop "$BACKEND_CONTAINER"
if [ $? -ne 0 ]; then
  echo "ERRO: Falha ao parar o backend" >&2
  exit 6
fi
echo "[INFO] Backend parado com sucesso!"

# Para PgBouncer se estiver rodando
if docker ps -a --format '{{.Names}}' | grep -q "^${PGBOUNCER_CONTAINER}$"; then
  echo "[INFO] Parando PgBouncer existente..."
  docker container stop "$PGBOUNCER_CONTAINER" 2>/dev/null || true
  echo "[INFO] PgBouncer parado!"
fi

# Nome do novo banco
NEW_DB="whazing_$(date '+%Y%m%d_%H%M')"
echo "[INFO] Criando novo banco: $NEW_DB"
docker exec -i "$CONTAINER_NAME" psql -U "$POSTGRES_USER" -c "CREATE DATABASE \"$NEW_DB\";"
if [ $? -ne 0 ]; then
  echo "ERRO: Falha ao criar banco de dados" >&2
  docker container start "$BACKEND_CONTAINER"
  exit 7
fi
echo "[INFO] Banco criado com sucesso!"

# Descompacta backup
echo "[INFO] Descompactando backup..."
gunzip -c "$BACKUP_FILE" > "$TEMP_SQL"
if [ $? -ne 0 ]; then
  echo "ERRO: Falha ao descompactar backup" >&2
  docker container start "$BACKEND_CONTAINER"
  exit 8
fi
echo "[INFO] Backup descompactado. Tamanho: $(ls -lh "$TEMP_SQL" | awk '{print $5}')"

# Restaura dentro do container
echo "[INFO] Restaurando backup no banco $NEW_DB (isso pode demorar)..."
cat "$TEMP_SQL" | docker exec -i "$CONTAINER_NAME" psql -U "$POSTGRES_USER" -d "$NEW_DB" 2>&1
RESTORE_EXIT=$?
if [ $RESTORE_EXIT -ne 0 ]; then
  echo "ERRO: Falha ao restaurar backup. Exit code: $RESTORE_EXIT" >&2
  rm -f "$TEMP_SQL"
  docker container start "$BACKEND_CONTAINER"
  exit 9
fi
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

# Remove \r novamente (caso tenha sido adicionado)
sed -i 's/\r$//' "$ENV_FILE" 2>/dev/null || true

# DEBUG: Verifica valor atual de DB_PORT
echo ""
echo "############################################################"
echo "[DEBUG] Verificando se precisa recriar PgBouncer..."
echo "  DB_PORT atual: ${DB_PORT:-5432}"
echo "  Comparação: DB_PORT == 6432 ? $( [[ "${DB_PORT:-5432}" == "6432" ]] && echo 'SIM' || echo 'NÃO' )"
echo "############################################################"
echo ""

# Recria PgBouncer se estiver em uso
if [[ "${DB_PORT:-5432}" == "6432" ]]; then
  echo ""
  echo "############################################################"
  echo "[INFO] DETECTADO: DB_PORT=6432 - PgBouncer será recriado"
  echo "############################################################"
  
  # Mostra container atual se existir
  if docker ps -a --format '{{.Names}}\t{{.Status}}' | grep "$PGBOUNCER_CONTAINER"; then
    echo "[INFO] Container PgBouncer existente encontrado:"
    docker ps -a --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' | grep -E "NAMES|$PGBOUNCER_CONTAINER"
  fi
  
  # Remove container antigo completamente
  echo "[INFO] Removendo container antigo..."
  docker container stop "$PGBOUNCER_CONTAINER" 2>/dev/null || true
  docker container rm "$PGBOUNCER_CONTAINER" 2>/dev/null || true
  sleep 2
  
  echo ""
  echo "[INFO] Criando novo container PgBouncer:"
  echo "  Banco: $NEW_DB"
  echo "  User: $POSTGRES_USER"
  echo "  Password: ${POSTGRES_PASSWORD:+***SET***}"
  echo "  Porta: 6432"
  echo ""
  
  # Comando completo pra debug
  PGBOUNCER_CMD="docker run -d \
    --name $PGBOUNCER_CONTAINER \
    --restart=always \
    --network host \
    -e DATABASES=\"postgres=host=127.0.0.1 port=5432 dbname=$NEW_DB user=$POSTGRES_USER password=${POSTGRES_PASSWORD}\" \
    -e POOL_MODE=transaction \
    -e LISTEN_PORT=6432 \
    -e MAX_CLIENT_CONN=1000 \
    -e DEFAULT_POOL_SIZE=25 \
    pgbouncer/pgbouncer"
  
  echo "[DEBUG] Executando comando:"
  echo "$PGBOUNCER_CMD"
  echo ""
  
  # Executa
  eval $PGBOUNCER_CMD
  PGBOUNCER_EXIT=$?
  
  if [ $PGBOUNCER_EXIT -ne 0 ]; then
    echo ""
    echo "ERRO: Falha ao recriar PgBouncer. Exit code: $PGBOUNCER_EXIT" >&2
    echo "[INFO] Tentando iniciar backend mesmo assim..." >&2
    docker container start "$BACKEND_CONTAINER"
    exit 11
  fi
  
  echo "[INFO] Container criado! Aguardando inicialização..."
  sleep 5
  
  # Verifica se PgBouncer está rodando
  echo ""
  if docker ps --format '{{.Names}}\t{{.Status}}' | grep -q "^${PGBOUNCER_CONTAINER}"; then
    echo "[SUCESSO] PgBouncer está rodando:"
    docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' | grep -E "NAMES|$PGBOUNCER_CONTAINER"
    echo ""
    echo "[INFO] Testando conexão com PgBouncer..."
    docker exec -i "$PGBOUNCER_CONTAINER" psql -h 127.0.0.1 -p 6432 -U "$POSTGRES_USER" -d postgres -c "SELECT version();" 2>&1 || echo "[AVISO] Teste de conexão falhou"
  else
    echo "[AVISO] PgBouncer pode não ter iniciado corretamente!" >&2
    echo ""
    echo "Logs do PgBouncer:"
    docker logs "$PGBOUNCER_CONTAINER" 2>&1 | tail -20
    echo ""
  fi
else
  echo ""
  echo "############################################################"
  echo "[INFO] DB_PORT != 6432 - PgBouncer NÃO será recriado"
  echo "############################################################"
  echo ""
fi

# Inicia backend
echo ""
echo "[INFO] Iniciando backend..."
docker container start "$BACKEND_CONTAINER"
if [ $? -ne 0 ]; then
  echo "ERRO: Falha ao iniciar backend" >&2
  exit 10
fi

# Aguarda backend inicializar
sleep 3

echo ""
echo "############################################################"
echo "[SUCESSO] Restauração concluída!"
echo "############################################################"
echo ""
echo "  Novo banco: $NEW_DB"
if [[ "${DB_PORT:-5432}" == "6432" ]]; then
  echo "  PgBouncer: recriado e rodando na porta 6432"
fi
echo "  Backend: reiniciado"
echo ""
echo "Containers rodando:"
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' | grep -E "NAMES|$BACKEND_CONTAINER|$PGBOUNCER_CONTAINER|$CONTAINER_NAME"
echo ""
echo "Comandos úteis:"
echo "  Backend logs:    docker logs -f $BACKEND_CONTAINER"
if [[ "${DB_PORT:-5432}" == "6432" ]]; then
  echo "  PgBouncer logs:  docker logs -f $PGBOUNCER_CONTAINER"
fi
echo "  PostgreSQL logs: docker logs -f $CONTAINER_NAME"
echo ""
echo "############################################################"