#!/bin/bash
# 
# functions for setting up WuzAPI

#######################################
# installs wuzapi
# Arguments:
#   None
#######################################
wuzapi_install() {
  print_banner
  printf "${WHITE} 💻 Instalando WuzAPI...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  ADMIN_TOKEN=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 30)
  DB_PASSWORD=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 15)

  sudo su - deploy <<EOF
cat > /home/deploy/wuzapi.yaml <<YAML
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
      - TZ=${timezonetext}
      - WEBHOOK_FORMAT=json
      - LOG_LEVEL=error
      - RABBITMQ_URL=amqp://wuzapi:wuzapi@rabbitmq:5672/
      - RABBITMQ_QUEUE=whatsapp_events
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

  # Salva o token em arquivo temporário para uso posterior
  echo "${ADMIN_TOKEN}" > /root/wuzapi_token.tmp

  sleep 20
}

#######################################
# configures wuzapi in database
# Arguments:
#   None
#######################################
wuzapi_configure_db() {
  print_banner
  printf "${WHITE} 💻 Configurando WuzAPI no banco de dados...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  # Lê o token salvo
  ADMIN_TOKEN=$(cat /root/wuzapi_token.tmp 2>/dev/null || echo "")

  if [ -z "$ADMIN_TOKEN" ]; then
    printf "${RED} ❌ Erro: Token do WuzAPI não encontrado${NC}\n"
    return 1
  fi

  sudo su - root <<EOF
  # Aguarda o banco estar pronto
  sleep 20

  # Atualiza o token do WuzAPI
  docker exec postgresql psql -U whazing -d postgres -c "
    UPDATE \"SettingsGeneral\" 
    SET value = '${ADMIN_TOKEN}' 
    WHERE key = 'WuzapiToken';
  " 2>/dev/null || echo "Aviso: Não foi possível atualizar WuzapiToken (pode não existir ainda)"

  # Ativa o WuzAPI
  docker exec postgresql psql -U whazing -d postgres -c "
    UPDATE \"SettingsGeneral\" 
    SET value = 'enabled' 
    WHERE key = 'Wuzapi';
  " 2>/dev/null || echo "Aviso: Não foi possível atualizar Wuzapi (pode não existir ainda)"

EOF

  sleep 10
}