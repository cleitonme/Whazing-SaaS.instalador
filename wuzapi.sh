#!/bin/bash
set -e

# =========================
# CONFIG
# =========================

TIMEZONE=$(timedatectl | grep "Time zone" | awk '{print $3}')
YAML_PATH="/home/deploy/wuzapi.yaml"

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

print_banner() {
  printf "${CYAN}${BOLD}========================================${NC}\n"
}

log() {
  printf "${CYAN}➜ %s${NC}\n" "$1"
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
  sleep 2
}

# =========================
# UTIL
# =========================

generate_token() {
  tr -dc A-Za-z0-9 </dev/urandom | head -c 30
}

generate_password() {
  tr -dc A-Za-z0-9 </dev/urandom | head -c 15
}

# =========================
# INSTALAÇÃO
# =========================

install_wuzapi() {
  log "Instalando WuzAPI..."

  ADMIN_TOKEN=$(generate_token)
  DB_PASSWORD=$(generate_password)

  sudo su - deploy <<EOF
cat > $YAML_PATH <<YAML
services:
  wuzapi-server:
    image: whazing/wuzapi:latest
    container_name: wuzapi
    ports:
      - "8080:8080"
    environment:
      - WUZAPI_ADMIN_TOKEN=${ADMIN_TOKEN}
      - DB_USER=wuzapi
      - DB_PASSWORD=${DB_PASSWORD}
      - DB_NAME=wuzapi
      - DB_HOST=db
      - DB_PORT=5432
      - TZ=${TIMEZONE}
      - WEBHOOK_FORMAT=json
      - LOG_LEVEL=error
      # RabbitMQ configuration Optional
      - RABBITMQ_URL=amqp://wuzapi:wuzapi@rabbitmq:5672/
      - RABBITMQ_QUEUE=whatsapp_events
      # Retry
      - WEBHOOK_RETRY_ENABLED=true
      - WEBHOOK_RETRY_COUNT=10
      - WEBHOOK_RETRY_DELAY_SECONDS=30
      - WEBHOOK_ERROR_QUEUE_NAME=wuzapi_dead_letter_webhooks
    depends_on:
      db:
        condition: service_healthy
      rabbitmq:
        condition: service_healthy
    networks:
      - wuzapi-network
    restart: always

  db:
    image: postgres:17.2
    container_name: postgreswuzapi
    environment:
      POSTGRES_USER: wuzapi
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_DB: wuzapi
    volumes:
      - db_data:/var/lib/postgresql/data
    networks:
      - wuzapi-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U wuzapi"]
      interval: 5s
      timeout: 5s
      retries: 5
    restart: always

  rabbitmq:
    image: rabbitmq:3-management
    container_name: rabbitmqwuzapi
    environment:
      RABBITMQ_DEFAULT_USER: wuzapi
      RABBITMQ_DEFAULT_PASS: wuzapi
      RABBITMQ_DEFAULT_VHOST: /
    ports:
      - "5672:5672"
      - "15672:15672"
    volumes:
      - rabbitmq_data:/var/lib/rabbitmq
    networks:
      - wuzapi-network
    healthcheck:
      test: ["CMD", "rabbitmq-diagnostics", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5
    restart: always

networks:
  wuzapi-network:
    driver: bridge

volumes:
  db_data:
  rabbitmq_data:
YAML

cd /home/deploy
docker compose -f wuzapi.yaml up -d
docker network connect bridge wuzapi || true
EOF

  print_banner
  printf "${GREEN}${BOLD}✅ INSTALAÇÃO CONCLUÍDA${NC}\n"
  print_banner

  printf "\n${WHITE}🌐 URL:${NC} http://127.0.0.1:8080\n"
  printf "${WHITE}🔑 TOKEN:${NC} ${ADMIN_TOKEN}\n"
  printf "${WHITE}🗄 SENHA DB:${NC} ${DB_PASSWORD}\n\n"
}

# =========================
# UPDATE
# =========================

update_wuzapi() {
  log "Atualizando WuzAPI..."

  sudo su - deploy <<EOF
cd /home/deploy
docker compose -f $YAML_PATH pull wuzapi-server
docker compose -f $YAML_PATH up -d --no-deps --force-recreate wuzapi-server
docker network connect bridge wuzapi || true
EOF

  ADMIN_TOKEN=$(grep "WUZAPI_ADMIN_TOKEN=" "$YAML_PATH" | cut -d '=' -f2)
  DB_PASSWORD=$(grep "DB_PASSWORD=" "$YAML_PATH" | cut -d '=' -f2)

  log_ok "Atualização concluída"
  printf "\n${WHITE}🌐 URL:${NC} http://127.0.0.1:8080\n"
  printf "${WHITE}🔑 TOKEN:${NC} ${ADMIN_TOKEN}\n"
  printf "${WHITE}🗄 SENHA DB:${NC} ${DB_PASSWORD}\n\n"
}

# =========================
# INÍCIO
# =========================

clear
print_banner
printf "${BOLD}🚀 WUZAPI MANAGER${NC}\n"
print_banner

# VERIFICA DISCO
verifica_disco

if [ -f "$YAML_PATH" ]; then
  update_wuzapi
else
  install_wuzapi
fi