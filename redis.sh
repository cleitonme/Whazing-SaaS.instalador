#!/bin/bash
set -euo pipefail

# =========================
# CONFIG
# =========================

ENV_FILE="/home/deploy/whazing/backend/.env"
BACKEND_CONTAINER="whazing-backend"
REDIS_CONTAINER="redis-whazing"

# =========================
# CORES
# =========================

RED='\033[1;31m'
YELLOW='\033[1;33m'
GREEN='\033[1;32m'
CYAN='\033[1;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m'

# =========================
# LOGS BONITOS
# =========================

log() {
  printf "${CYAN}[ %s ]${NC} %s\n" "$(date '+%Y-%m-%d %H:%M:%S')" "$1"
}

log_ok() {
  printf "${GREEN}✔ %s${NC}\n" "$1"
}

log_warn() {
  printf "${YELLOW}⚠ %s${NC}\n" "$1"
}

log_error() {
  printf "${RED}✖ %s${NC}\n" "$1"
}

print_banner() {
  printf "${CYAN}${BOLD}========================================${NC}\n"
}

# =========================
# VERIFICA DISCO
# =========================

verifica_disco() {
  uso=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')

  total=30
  preenchido=$((uso * total / 100))
  vazio=$((total - preenchido))

  barra_cheia=$(printf "%0.s█" $(seq 1 $preenchido))
  barra_vazia=$(printf "%0.s░" $(seq 1 $vazio))

  print_banner
  printf "${BOLD}💾 STATUS DO DISCO${NC}\n"
  print_banner

  printf "\n${WHITE}Uso atual:${NC} ${BOLD}%s%%${NC}\n\n" "$uso"

  if [ "$uso" -ge 95 ]; then COR=$RED
  elif [ "$uso" -ge 90 ]; then COR=$RED
  elif [ "$uso" -ge 80 ]; then COR=$YELLOW
  else COR=$GREEN
  fi

  printf "${COR}[%s%s] %s%%${NC}\n\n" "$barra_cheia" "$barra_vazia" "$uso"

  if [ "$uso" -ge 95 ]; then
    log_error "DISCO CRÍTICO - operação cancelada"
    exit 1
  elif [ "$uso" -ge 90 ]; then
    log_warn "Alto risco de falha"
  elif [ "$uso" -ge 80 ]; then
    log_warn "Espaço quase cheio"
  else
    log_ok "Disco OK"
  fi

  printf "\n"
}

# =========================
# INÍCIO
# =========================

clear
print_banner
printf "${BOLD}🚀 REINSTALAÇÃO REDIS + BACKEND${NC}\n"
print_banner
printf "\n"

# Verifica disco antes de tudo
verifica_disco

# =========================
# VALIDAÇÕES
# =========================

if [[ ! -f "$ENV_FILE" ]]; then
  log_error "Arquivo .env não encontrado: $ENV_FILE"
  exit 2
fi

# Remove CRLF
sed -i 's/\r$//' "$ENV_FILE"

# Carrega ENV
set -a
source "$ENV_FILE"
set +a

if [[ -z "${IO_REDIS_PORT:-}" || -z "${IO_REDIS_PASSWORD:-}" ]]; then
  log_error "IO_REDIS_PORT ou IO_REDIS_PASSWORD não definidos"
  exit 3
fi

TZ_LOCAL=$(timedatectl show -p Timezone --value || echo "UTC")

# =========================
# EXECUÇÃO
# =========================

log "Parando containers..."
docker stop "$BACKEND_CONTAINER" || true
docker stop "$REDIS_CONTAINER" || true
log_ok "Containers parados"

log "Removendo Redis antigo..."
docker rm "$REDIS_CONTAINER" || true
log_ok "Redis removido"

log "Limpando imagens Docker..."
docker image prune -f
log_ok "Limpeza concluída"

log "Subindo Redis..."
docker run --name "$REDIS_CONTAINER" \
  -e TZ="$TZ_LOCAL" \
  -p "$IO_REDIS_PORT:6379" \
  --restart=always \
  --memory=3g \
  -d redis:latest redis-server \
    --requirepass "$IO_REDIS_PASSWORD" \
    --maxclients 10000 \
    --tcp-keepalive 60 \
    --maxmemory 2gb \
    --maxmemory-policy noeviction \
    --save "" \
    --appendonly no \
    --lazyfree-lazy-eviction yes \
    --lazyfree-lazy-expire yes \
    --lazyfree-lazy-server-del yes

log_ok "Redis rodando"

log "Iniciando backend..."
docker start "$BACKEND_CONTAINER"
log_ok "Backend iniciado"

print_banner
printf "${GREEN}${BOLD}✅ PROCESSO FINALIZADO COM SUCESSO${NC}\n"
print_banner

printf "\n${WHITE}📡 Backend online${NC}\n"
printf "${WHITE}⚡ Redis pronto${NC}\n\n"

sleep 5