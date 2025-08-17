#!/bin/bash

# Detecta timezone do sistema
timezonetext=$(timedatectl | grep "Time zone" | awk '{print $3}')

print_banner() {
  echo "=============================="
}

whazing_atualizar() {
  download_docker_imagem_estavel
  backend_docker_remove
  backend_docker_start
  frontend_docker_start
  limpa_docker_imagem
  atualizacao_terminado
}

download_docker_imagem_estavel() {
  print_banner
  echo "💻 Baixando imagens (whazing)..."
  sleep 2

  sudo su - deploy <<EOF
cd /home/deploy/whazing/frontend
docker pull --disable-content-trust=1 whazing/whazing-frontend:latest
docker pull --disable-content-trust=1 whazing/whazing-backend:latest
EOF

  sleep 2
}

backend_docker_remove() {
  print_banner
  echo "💻 Removendo possíveis instalações antigas..."
  sleep 2

  sudo su - deploy <<EOF
docker stop whazing-backend || true
docker rm whazing-backend || true
docker stop whazing-frontend || true
docker rm whazing-frontend || true
EOF
}

backend_docker_start() {
  print_banner
  echo "💻 Atualizando backend..."
  sleep 2

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
  whazing/whazing-backend:latest
EOF
  sleep 2
}

frontend_docker_start() {
  print_banner
  echo "💻 Atualizando frontend..."
  sleep 2

  sudo su - deploy <<EOF
cd /home/deploy/whazing/frontend
docker run -d \
  --name whazing-frontend \
  -p 3333:8087 \
  --restart=always \
  -v /home/deploy/whazing/frontend/.env:/app/.env \
  whazing/whazing-frontend:latest
EOF
  sleep 2
}

limpa_docker_imagem() {
  print_banner
  echo "💻 Limpando imagens não usadas..."
  sleep 2

  sudo su - deploy <<EOF
docker image prune -f
EOF
  sleep 2
}

atualizacao_terminado() {
  print_banner
  echo "✅ Processo finalizado!"
  echo "Agora você pode voltar a usar o sistema."
  sleep 5
}

# Executa a atualização
whazing_atualizar
