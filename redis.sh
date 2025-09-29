#!/bin/bash
set -euo pipefail

# Caminho do .env
ENV_FILE="/home/deploy/whazing/backend/.env"
sed -i 's/\r$//' "$ENV_FILE"

# Containers
BACKEND_CONTAINER="whazing-backend"
REDIS_CONTAINER="redis-whazing"

log() { echo "[ $(date '+%Y-%m-%d %H:%M:%S') ] $*"; }

if [[ ! -f "$ENV_FILE" ]]; then
  echo "ERRO: arquivo .env não encontrado em: $ENV_FILE" >&2
  exit 2
fi

# Carrega variáveis do .env
set -a
source "$ENV_FILE"
set +a

# Valida variáveis obrigatórias
if [[ -z "${IO_REDIS_PORT:-}" || -z "${IO_REDIS_PASSWORD:-}" ]]; then
  echo "ERRO: IO_REDIS_PORT ou IO_REDIS_PASSWORD não definidos no .env" >&2
  exit 3
fi

# Detecta timezone local
TZ_LOCAL=$(timedatectl show -p Timezone --value || echo "UTC")

log "Parando containers..."
docker stop "$BACKEND_CONTAINER" || true
docker stop "$REDIS_CONTAINER" || true

log "Removendo container antigo do Redis..."
docker rm "$REDIS_CONTAINER" || true

log "Limpando imagens não utilizadas..."
docker image prune -f

log "Reinstalando Redis na porta $IO_REDIS_PORT com timezone $TZ_LOCAL..."
docker run --name "$REDIS_CONTAINER" \
  -e TZ="$TZ_LOCAL" \
  -p "$IO_REDIS_PORT:6379" \
  --restart=always \
  -d redis:latest redis-server \
    --requirepass "$IO_REDIS_PASSWORD" \
    --maxclients 2000 \
    --tcp-keepalive 60 \
    --maxmemory-policy allkeys-lru \
    --save "" \
    --appendonly yes \
    --appendfsync everysec

log "Redis reinstalado com sucesso."

log "Iniciando novamente o backend..."
docker start "$BACKEND_CONTAINER"

log "Mostrando últimos logs do backend (Ctrl+C para sair)..."
docker logs -f "$BACKEND_CONTAINER" --tail 100