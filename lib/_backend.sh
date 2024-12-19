#!/bin/bash
# 
# functions for setting up app backend

#######################################
# creates docker db
# Arguments:
#   None
#######################################
backend_db_create() {
  print_banner
  printf "${WHITE} 💻 Criando banco de dados...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - root <<EOF
  usermod -aG docker deploy
  mkdir -p /data
  chown -R 999:999 /data
  docker run --name postgresql \
                -e POSTGRES_USER=whazing \
                -e POSTGRES_PASSWORD=${pg_pass} \
				-e TZ="America/Sao_Paulo" \
                -p 5432:5432 \
                --restart=always \
                -v /data:/var/lib/postgresql/data \
                -d postgres
  docker exec -u root postgresql bash -c "chown -R postgres:postgres /var/lib/postgresql/data"
  docker run --name redis-whazing \
                -e TZ="America/Sao_Paulo" \
                -p 6383:6379 \
                --restart=always \
                -d redis:latest redis-server \
                --appendonly yes \
                --requirepass "${redis_pass}" \
				--tcp-keepalive 0 \
				--maxclients 10000
				
 
  docker run -d --name portainer \
                -p 9000:9000 -p 9443:9443 \
                --restart=always \
                -v /var/run/docker.sock:/var/run/docker.sock \
                -v portainer_data:/data portainer/portainer-ce
EOF

  sleep 2
}

#######################################
# sets environment variable for backend.
# Arguments:
#   None
#######################################
backend_set_env() {
  print_banner
  printf "${WHITE} 💻 Configurando variáveis de ambiente (backend)...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  # ensure idempotency
  backend_url=$(echo "${backend_url/https:\/\/}")
  backend_url=${backend_url%%/*}
  backend_url=https://$backend_url

  # ensure idempotency
  frontend_url=$(echo "${frontend_url/https:\/\/}")
  frontend_url=${frontend_url%%/*}
  frontend_url=https://$frontend_url
  
  jwt_secret=$(openssl rand -base64 32)
  jwt_refresh_secret=$(openssl rand -base64 32)

sudo su - deploy << EOF
  cat <<[-]EOF > /home/deploy/whazing/backend/.env
NODE_ENV=
BACKEND_URL=${backend_url}
FRONTEND_URL=${frontend_url}
ADMIN_DOMAIN=whazing.io

PROXY_PORT=443
PORT=3000

# conexão com o banco de dados
DB_DIALECT=postgres
DB_PORT=5432
DB_TIMEZONE=-03:00
POSTGRES_HOST=localhost
POSTGRES_USER=whazing
POSTGRES_PASSWORD=${pg_pass}
POSTGRES_DB=postgres

# Chaves para criptografia do token jwt
JWT_SECRET=${jwt_secret}
JWT_REFRESH_SECRET=${jwt_refresh_secret}

# Dados de conexão com o REDIS
IO_REDIS_SERVER=localhost
IO_REDIS_PASSWORD=${redis_pass}
IO_REDIS_PORT=6383
IO_REDIS_DB_SESSION=2

# tempo para randomização da mensagem de horário de funcionamento
MIN_SLEEP_BUSINESS_HOURS=1000
MAX_SLEEP_BUSINESS_HOURS=2000

# tempo para randomização das mensagens do bot
MIN_SLEEP_AUTO_REPLY=400
MAX_SLEEP_AUTO_REPLY=600

# tempo para randomização das mensagens gerais
MIN_SLEEP_INTERVAL=200
MAX_SLEEP_INTERVAL=500

# dados do RabbitMQ / Para não utilizar, basta comentar a var AMQP_URL
RABBITMQ_DEFAULT_USER=whazing
RABBITMQ_DEFAULT_PASS=${rabbit_pass}
#AMQP_URL='amqp://whazing:${rabbit_pass}@localhost:5672?connection_attempts=5&retry_delay=5'

# api oficial (integração em desenvolvimento)
API_URL_360=https://waba-sandbox.360dialog.io

# usado para mosrar opções não disponíveis normalmente.
ADMIN_DOMAIN=whazing.io

# Dados para utilização do canal do facebook
FACEBOOK_APP_ID=3237415623048660
FACEBOOK_APP_SECRET_KEY=3266214132b8c98ac59f3e957a5efeaaa13500

# Limitar Uso do whazing Usuario e Conexões
USER_LIMIT=999
CONNECTIONS_LIMIT=999

#config banco
DB_DEBUG=false
POSTGRES_POOL_MAX=100
POSTGRES_POOL_MIN=10
POSTGRES_POOL_ACQUIRE=30000
POSTGRES_POOL_IDLE=10000
POSTGRES_REQUEST_TIMEOUT=600000

TIMEOUT_TO_IMPORT_MESSAGE=1000

[-]EOF
EOF

  sleep 2
}

#######################################
# installs node.js dependencies
# Arguments:
#   None
#######################################
backend_node_dependencies() {
  print_banner
  printf "${WHITE} 💻 Instalando dependências do backend...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - deploy <<EOF
  cd /home/deploy/whazing/backend
  npm install --force
EOF

  sleep 2
}

#######################################
# compiles backend code
# Arguments:
#   None
#######################################
backend_node_build() {
  print_banner
  printf "${WHITE} 💻 Compilando o código do backend...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - deploy <<EOF
  cd /home/deploy/whazing/backend

EOF

  sleep 2
}

#######################################
# runs db migrate
# Arguments:
#   None
#######################################
backend_db_migrate() {
  print_banner
  printf "${WHITE} 💻 Executando db:migrate...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - deploy <<EOF
  cd /home/deploy/whazing/backend
  npx sequelize db:migrate
EOF

  sleep 2
}

#######################################
# runs db seed
# Arguments:
#   None
#######################################
backend_db_seed() {
  print_banner
  printf "${WHITE} 💻 Executando db:seed...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - deploy <<EOF
  cd /home/deploy/whazing/backend
  npx sequelize db:seed:all
EOF

  sleep 2
}

#######################################
# starts backend using pm2 in 
# production mode.
# Arguments:
#   None
#######################################
backend_start_pm2() {
  print_banner
  printf "${WHITE} 💻 Iniciando pm2 (backend)...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - deploy <<EOF
  cd /home/deploy/whazing/backend
  pm2 start dist/server.js --name whazing-backend
  pm2 save
EOF

  sleep 2
}

#######################################
# updates frontend code
# Arguments:
#   None
#######################################
backend_nginx_setup() {
  print_banner
  printf "${WHITE} 💻 Configurando nginx (backend)...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  backend_hostname=$(echo "${backend_url/https:\/\/}")

sudo su - root << EOF

cat > /etc/nginx/sites-available/whazing-backend << 'END'
server {
  server_name $backend_hostname;
  
  location / {
    proxy_pass http://127.0.0.1:3000;
    proxy_http_version 1.1;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection 'upgrade';
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_cache_bypass \$http_upgrade;
  }
}
END

ln -s /etc/nginx/sites-available/whazing-backend /etc/nginx/sites-enabled
EOF

  sleep 2
}
