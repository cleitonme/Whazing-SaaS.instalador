#!/bin/bash

set -e

# Detecta timezone do sistema
timezonetext=$(timedatectl | grep "Time zone" | awk '{print $3}')

# Cores
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

log_step() {
  printf "\n${CYAN}${BOLD}➜ %s${NC}\n" "$1"
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

whazing_atualizar() {
  verifica_disco
  limpa_docker_imagem
  download_docker_imagem_estavel
  backend_docker_remove
  backend_docker_start
  frontend_docker_start
  atualizacao_terminado
}

verifica_disco() {
  clear
  uso=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')

  total=30
  preenchido=$((uso * total / 100))
  vazio=$((total - preenchido))

  barra_cheia=$(printf "%0.s█" $(seq 1 $preenchido))
  barra_vazia=$(printf "%0.s░" $(seq 1 $vazio))

  print_banner
  printf "${BOLD}        🚨 STATUS DO DISCO 🚨${NC}\n"
  print_banner
  printf "\n${WHITE}Uso atual:${NC} ${BOLD}%s%%${NC}\n\n" "$uso"

  if [ "$uso" -ge 95 ]; then COR=$RED
  elif [ "$uso" -ge 90 ]; then COR=$RED
  elif [ "$uso" -ge 80 ]; then COR=$YELLOW
  else COR=$GREEN
  fi

  printf "${COR}[%s%s] %s%%${NC}\n\n" "$barra_cheia" "$barra_vazia" "$uso"

  if [ "$uso" -ge 95 ]; then
    log_error "DISCO CRÍTICO - Atualização cancelada"
    exit 1
  elif [ "$uso" -ge 90 ]; then
    log_error "Alto risco de falha!"
  elif [ "$uso" -ge 80 ]; then
    log_warn "Espaço quase cheio"
  else
    log_ok "Disco OK"
  fi

  sleep 2
}

download_docker_imagem_estavel() {
  log_step "Baixando imagens (whazing)..."

  sudo su - deploy <<EOF
docker pull whazing/whazing-frontend:beta
docker pull whazing/whazing-backend:beta
EOF

  log_ok "Imagens atualizadas"
}

backend_docker_remove() {
  log_step "Removendo containers antigos..."

  sudo su - deploy <<EOF
docker stop whazing-backend || true
docker rm whazing-backend || true
docker stop whazing-frontend || true
docker rm whazing-frontend || true
EOF

  log_ok "Containers antigos removidos"
}

backend_docker_start() {
  log_step "Subindo backend..."

  sudo su - deploy <<EOF
cd /home/deploy/whazing/backend
docker run -d \
  --name whazing-backend \
  --network host \
  --restart=always \
  -e TZ=${timezonetext} \
  -v /etc/localtime:/etc/localtime:ro \
  -v /home/deploy/whazing/backend/private:/app/private \
  -v /home/deploy/whazing/backend/public:/app/public \
  -v /home/deploy/whazing/backend/logs:/app/logs \
  -v /home/deploy/whazing/backend/.env:/app/.env \
  whazing/whazing-backend:beta
EOF

  log_ok "Backend rodando"
}

frontend_docker_start() {
  log_step "Subindo frontend..."

  sudo su - deploy <<EOF
cd /home/deploy/whazing/frontend
docker run -d \
  --name whazing-frontend \
  -p 3333:8087 \
  --restart=always \
  -v /home/deploy/whazing/frontend/.env:/app/.env \
  whazing/whazing-frontend:beta
EOF

  log_ok "Frontend rodando"
}

limpa_docker_imagem() {
  log_step "Limpando imagens Docker..."

  sudo su - deploy <<EOF
docker image prune -f
EOF

  log_ok "Limpeza concluída"
}

atualizacao_terminado() {
  clear
  print_banner

  printf "${GREEN}${BOLD}     ✅ ATUALIZAÇÃO CONCLUÍDA!${NC}\n"
  print_banner

  printf "\n${WHITE}🚀 Sistema atualizado com sucesso!${NC}\n"
  printf "${CYAN}📦 Containers reiniciados${NC}\n"
  printf "${CYAN}🧹 Ambiente limpo${NC}\n\n"

  printf "${GREEN}${BOLD}✔ Tudo operacional${NC}\n"

  sleep 5
}

# Execução
whazing_atualizar