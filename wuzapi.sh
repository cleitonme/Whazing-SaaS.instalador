#!/bin/bash
set -e

# Detecta timezone do sistema
TIMEZONE=$(timedatectl | grep "Time zone" | awk '{print $3}')
YAML_PATH="/home/deploy/wuzapi.yaml"

# Funções utilitárias
print_banner() {
  echo "=============================="
}

generate_token() {
  tr -dc A-Za-z0-9 </dev/urandom | head -c 30
}

generate_password() {
  tr -dc A-Za-z0-9 </dev/urandom | head -c 15
}

# Função principal de instalação
install_wuzapi() {
  print_banner
  echo "🚀 Instalando WuzAPI..."
  sleep 1

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
      - SESSION_DEVICE_NAME=Windows
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
docker network connect bridge wuzapi
EOF

  print_banner
  echo "✅ Instalação concluída!"
  echo "URL WuzAPI: http://127.0.0.1:8080"
  echo "Admin Token: ${ADMIN_TOKEN}"
  echo "DB Password: ${DB_PASSWORD}"
  echo "Arquivo: ${YAML_PATH}"
  echo "=============================="
}

# Função principal de atualização
update_wuzapi() {
  print_banner
  echo "🔄 Atualizando WuzAPI..."
  sleep 1

  sudo su - deploy <<EOF
cd /home/deploy
docker compose -f $YAML_PATH pull wuzapi-server
docker compose -f $YAML_PATH up -d --no-deps --force-recreate wuzapi-server
docker network connect bridge wuzapi
EOF

  ADMIN_TOKEN=$(grep "WUZAPI_ADMIN_TOKEN=" "$YAML_PATH" | cut -d '=' -f2)

  print_banner
  echo "✅ Atualização concluída!"
  echo "URL WuzAPI: http://127.0.0.1:8080"
  echo "Admin Token: ${ADMIN_TOKEN}"
  echo "=============================="
}

# Início do script
print_banner
echo "💻 Iniciando processo WuzAPI..."
sleep 1

if [ -f "$YAML_PATH" ]; then
  update_wuzapi
else
  install_wuzapi
fi
