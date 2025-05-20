#!/bin/bash
# 
# system management

#######################################
# creates user
# Arguments:
#   None
#######################################
system_create_user() {
  print_banner
  printf "${WHITE} 💻 Agora, vamos criar o usuário para deploy...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - root <<EOF
  useradd -m -s /bin/bash -G sudo deploy 2>/dev/null || echo "Usuário já existe, continuando..."
  echo "deploy:$senha" | chpasswd
  passwd -u deploy 2>/dev/null
  echo "deploy ALL=(ALL) NOPASSWD:ALL" | tee /etc/sudoers.d/deploy > /dev/null
  usermod -aG sudo deploy
EOF

  sleep 2
}


instalacao_firewall() {
  print_banner
  printf "${WHITE} 💻 Agora, vamos instalar e ativar firewall UFW...${GRAY_LIGHT}"
  printf "\n\n"
  sleep 2

  sudo bash -c '

# Impede que Docker interfira no iptables (respeita UFW)
echo "{
  \"iptables\": false
}" > /etc/docker/daemon.json

# Reinicia Docker para aplicar a configuração
systemctl restart docker

# Configura política padrão do UFW
ufw default deny incoming
ufw default allow outgoing

# Permite portas essenciais
ufw allow ssh
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 9000/tcp

# Corrige o FORWARD_POLICY
sed -i "s/^DEFAULT_FORWARD_POLICY=\"DROP\"/DEFAULT_FORWARD_POLICY=\"ACCEPT\"/" /etc/default/ufw

# Adiciona regra NAT para containers Docker
UFW_BEFORE_RULES="/etc/ufw/before.rules"
if ! grep -q "POSTROUTING -s 172.17.0.0/16" "$UFW_BEFORE_RULES"; then
  TMPFILE=$(mktemp)
  cat <<EORULES > "$TMPFILE"
*nat
:POSTROUTING ACCEPT [0:0]
-A POSTROUTING -s 172.17.0.0/16 ! -o docker0 -j MASQUERADE
COMMIT
EORULES
  cat "$UFW_BEFORE_RULES" >> "$TMPFILE"
  mv "$TMPFILE" "$UFW_BEFORE_RULES"
fi

# Recarrega UFW com novas regras
ufw --force enable
ufw reload
systemctl restart ufw

  '

  sleep 5
}


iniciar_firewall() {
  print_banner
  printf "${WHITE} 💻 Iniciando Firewall...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - root <<EOF
  service ufw start
  
EOF

  sleep 2
}

parar_firewall() {
  print_banner
  printf "${WHITE} 💻 Parando Firewall(atenção seu servidor ficara desprotegido)...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - root <<EOF
  service ufw stop
  
EOF

  sleep 2
}

#######################################
# set timezone
# Arguments:
#   None
#######################################
system_set_timezone() {
  print_banner
  printf "${WHITE} 💻 Setando timezone...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - root <<EOF
  timedatectl set-timezone ${timezonetext}
EOF

  sleep 2
}

#######################################
# unzip whazing
# Arguments:
#   None
#######################################
system_unzip_whazing() {
  print_banner
  printf "${WHITE} 💻 Fazendo clone whazing...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - deploy <<EOF
  git clone https://github.com/cleitonme/Whazing-SaaS.git /home/deploy/whazing
  cd /home/deploy/whazing
  unzip -o whazing.zip
  chmod 775 /home/deploy/whazing/ -Rf
  unzip -o logos.zip
  chmod 775 /home/deploy/whazing/ -Rf
EOF

  sleep 2
}

erro_banco() {
  print_banner
  printf "${WHITE} 💻 Estamos corrigindo...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - root <<EOF
  docker container restart postgresql
  docker exec -u root postgresql bash -c "chown -R postgres:postgres /var/lib/postgresql/data"
  docker container restart postgresql
  
EOF

  sleep 2
}

arruma_permissao() {
  print_banner
  printf "${WHITE} 💻 Garantindo permissões usuario deploy...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - root <<EOF
  chown deploy.deploy /home/deploy/whazing -Rf
  
EOF

  sleep 2
}

apagar_distsrc() {
  print_banner
  printf "${WHITE} 💻 Apagando arquivos versao anterior${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - root <<EOF
  cd /home/deploy/whazing/backend
  rm dist/ -Rf
  rm node_modules/ -Rf
  rm package.json -Rf
  rm package-lock.json -Rf
  cd /home/deploy/whazing/frontend  
  rm dist/ -Rf
  rm src/ -Rf
EOF

  sleep 2
}

#######################################
# updates whazing
# Arguments:
#   None
#######################################
git_update() {
  print_banner
  printf "${WHITE} 💻 Atualizando o whazing do git...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - deploy <<EOF
  cd /home/deploy/whazing
  pm2 stop all
  rm whazing.zip
  wget https://github.com/cleitonme/Whazing-SaaS/raw/refs/heads/main/whazing.zip
  unzip -o whazing.zip
  chmod 775 /home/deploy/whazing/ -Rf
EOF

  sleep 2
}

#######################################
# updates system
# Arguments:
#   None
#######################################
system_update() {
  print_banner
  printf "${WHITE} 💻 Vamos atualizar o sistema...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - root <<EOF
  apt -y update && apt -y upgrade
  apt autoremove -y
  sudo ufw allow 443/tcp
  sudo ufw allow 80/tcp
EOF

  sleep 2
}

#######################################
# installs node
# Arguments:
#   None
#######################################
system_node_install() {
  print_banner
  printf "${WHITE} 💻 Instalando nodejs...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - root <<EOF
  curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
  apt-get install -y nodejs
EOF

  sleep 2
}

#######################################
# installs docker
# Arguments:
#   None
#######################################
system_docker_install() {
  print_banner
  printf "${WHITE} 💻 Instalando docker...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - root <<EOF
  sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
  echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
  apt install -y docker-ce
EOF

  sleep 2
}

#######################################
# Ask for file location containing
# multiple URL for streaming.
# Globals:
#   WHITE
#   GRAY_LIGHT
#   BATCH_DIR
#   PROJECT_ROOT
# Arguments:
#   None
#######################################
system_puppeteer_dependencies() {
  print_banner
  printf "${WHITE} 💻 Instalando puppeteer dependencies...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - root <<EOF
apt install -y bash sudo curl
apt install -y ffmpeg ufw apt-transport-https ca-certificates software-properties-common curl libgbm-dev wget unzip fontconfig locales gconf-service libasound2 libatk1.0-0 libc6 libcairo2 libcups2 libdbus-1-3 libexpat1 libfontconfig1 libgcc1 libgconf-2-4 libgdk-pixbuf2.0-0 libglib2.0-0 libgtk-3-0 libnspr4 libpango-1.0-0 libpangocairo-1.0-0 libstdc++6 libx11-6 libx11-xcb1 libxcb1 libxcomposite1 libxcursor1 libxdamage1 libxext6 libxfixes3 libxi6 libxrandr2 libxrender1 libxss1 libxtst6 ca-certificates fonts-liberation libappindicator1 libnss3 lsb-release xdg-utils python2-minimal build-essential libxshmfence-dev nginx unzip fail2ban
EOF

  sleep 2
}

#######################################
# Ask for file location containing
# multiple URL for streaming.
# Globals:
#   WHITE
#   GRAY_LIGHT
#   BATCH_DIR
#   PROJECT_ROOT
# Arguments:
#   None
#######################################
system_puppeteerdocker_dependencies() {
  print_banner
  printf "${WHITE} 💻 Instalando puppeteer dependencies...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - root <<EOF
apt install -y bash sudo curl
apt install -y ufw apt-transport-https ca-certificates software-properties-common curl wget unzip locales gconf-service ca-certificates nginx unzip fail2ban
EOF

  sleep 2
}

system_pm2_stop() {
  print_banner
  printf "${WHITE} 💻 Parando o whazing...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - deploy <<EOF
  pm2 stop all
EOF

  sleep 2
}

system_pm2_start() {
  print_banner
  printf "${WHITE} 💻 Iniciando o whazing...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - deploy <<EOF
  pm2 start all
EOF

  sleep 2
}


#######################################
# installs pm2
# Arguments:
#   None
#######################################
system_pm2_install() {
  print_banner
  printf "${WHITE} 💻 Instalando pm2...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - root <<EOF
  npm install -g pm2
  pm2 startup ubuntu -u deploy
  env PATH=\$PATH:/usr/bin pm2 startup ubuntu -u deploy --hp /home/deploy
  echo "vm.overcommit_memory = 1" >> /etc/sysctl.conf
  sysctl -p
EOF

  sleep 2
}

system_otimizacao_system() {
  print_banner
  printf "${WHITE} 💻 otimizando sistema...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - root <<EOF
  echo "vm.overcommit_memory = 1" >> /etc/sysctl.conf
  sysctl -p
EOF

  sleep 2
}

#######################################
# otimizacao redis
# Arguments:
#   None
#######################################
system_sysctl() {
  print_banner
  printf "${WHITE} 💻 Alterando parametros sistema...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - root <<EOF
  echo "vm.overcommit_memory = 1" >> /etc/sysctl.conf
  echo never > /sys/kernel/mm/transparent_hugepage/enabled
  echo 'vm.swappiness = 1' >> /etc/sysctl.conf
  sysctl -p
EOF

  sleep 2
}


#######################################
# installs snapd
# Arguments:
#   None
#######################################
system_snapd_install() {
  print_banner
  printf "${WHITE} 💻 Instalando snapd...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - root <<EOF
  apt install -y snapd
  systemctl start snapd
  systemctl enable snapd
  snap install core
  snap refresh core
EOF

  sleep 2
}

#######################################
# installs certbot
# Arguments:
#   None
#######################################
system_certbot_install() {
  print_banner
  printf "${WHITE} 💻 Instalando certbot...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - root <<EOF
  apt-get remove certbot
  snap install --classic certbot
  ln -s /snap/bin/certbot /usr/bin/certbot
EOF

  sleep 2
}

#######################################
# installs nginx
# Arguments:
#   None
#######################################
system_nginx_install() {
  print_banner
  printf "${WHITE} 💻 Instalando nginx...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - root <<EOF
  rm /etc/nginx/sites-enabled/default
EOF

  sleep 2
}

#######################################
# install_chrome
# Arguments:
#   None
#######################################
system_set_user_mod() {
  print_banner
  printf "${WHITE} 💻 Setando user docker...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - root <<EOF
  sudo usermod -aG docker deploy
  su - deploy
EOF

  sleep 2
}

criar_cron() {
  print_banner
  printf "${WHITE} 💻 Criar cron...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - root <<EOF
(crontab -l -u deploy | grep -v "/usr/bin/node /usr/bin/pm2 restart all"; echo "0 */24 * * * /usr/bin/node /usr/bin/pm2 restart all") | crontab -u deploy -
EOF

  sleep 2
}

#######################################
# restarts nginx
# Arguments:
#   None
#######################################
system_nginx_restart() {
  print_banner
  printf "${WHITE} 💻 reiniciando nginx...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - root <<EOF
  service nginx restart
EOF

  sleep 2
}

#######################################
# setup for nginx.conf
# Arguments:
#   None
#######################################
system_nginx_conf() {
  print_banner
  printf "${WHITE} 💻 configurando nginx...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

sudo su - root << EOF

cat > /etc/nginx/conf.d/whazing.conf << 'END'
client_max_body_size 100M;
large_client_header_buffers 16 5120k;
END

EOF

  sleep 2
}

#######################################
# installs nginx
# Arguments:
#   None
#######################################
system_certbot_setup() {
  print_banner
  printf "${WHITE} 💻 Configurando certbot...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  backend_domain=$(echo "${backend_url/https:\/\/}")
  frontend_domain=$(echo "${frontend_url/https:\/\/}")
  admin_domain=$(echo "${admin_url/https:\/\/}")

  sudo su - root <<EOF
  certbot -m cleitonme@gmail.com \
          --nginx \
          --agree-tos \
          --non-interactive \
          --domains $backend_domain,$frontend_domain
EOF

  sleep 2
}

#######################################
# reboot
# Arguments:
#   None
#######################################
system_reboot() {
  print_banner
  printf "${WHITE} 💻 Reboot...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - root <<EOF
  reboot
EOF

  sleep 2
}

#######################################
# creates docker db
# Arguments:
#   None
#######################################
system_docker_start() {
  print_banner
  printf "${WHITE} 💻 Iniciando container docker...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - root <<EOF
  docker stop $(docker ps -q)
  docker container start postgresql
  docker container start redis-whazing
  docker exec -u root postgresql bash -c "chown -R postgres:postgres /var/lib/postgresql/data"
EOF

  sleep 2
}

#######################################
# creates docker db
# Arguments:
#   None
#######################################
system_docker_restart() {
  print_banner
  printf "${WHITE} 💻 Iniciando container docker...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - root <<EOF
  docker container restart redis-whazing
  docker container restart portainer
  docker container restart postgresql
  docker exec -u root postgresql bash -c "chown -R postgres:postgres /var/lib/postgresql/data"
EOF

  sleep 5
}



#######################################
# creates final message
# Arguments:
#   None
#######################################
system_success() {

echo $senha > /root/senhadeploy

  print_banner
  printf "${GREEN} 💻 Instalação concluída com Sucesso...${NC}"
  printf "${CYAN_LIGHT}";
  printf "\n\n"
  printf "\n"
  printf "Usuário: admin@admin.com"
  printf "\n"
  printf "Senha: 123456"
  printf "\n"
  printf "URL front: https://$frontend_domain"
  printf "\n"
  printf "URL back: https://$backend_domain"
  printf "\n"
  printf "Senha Usuario deploy: $senha"
  printf "\n"
  printf "Usuario do Banco de Dados: whazing"
  printf "\n"
  printf "Nome do Banco de Dados: postgres"
  printf "\n"
  printf "Senha do Banco de Dados: $senha"
  printf "\n"
  printf "Senha do Redis: $senha"
  printf "\n"
  printf "${NC}";

  sleep 2
}

#######################################
# updates whazing
# Arguments:
#   None
#######################################
update_beta() {
  print_banner
  printf "${WHITE} 💻 Atualizando o whazing Beta...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - deploy <<EOF
  cd /home/deploy/whazing
  pm2 stop all
  rm whazing.zip
  wget https://github.com/cleitonme/Whazing-SaaS-Beta/raw/refs/heads/main/whazing.zip
  unzip -o whazing.zip
  chmod 775 /home/deploy/whazing/ -Rf
EOF

  sleep 2
}

Recurso_Premium() {


  print_banner
  printf "${GREEN} Recurso exclusivo da versão premium...${NC}"
  printf "${CYAN_LIGHT}";
  printf "\n\n"
  printf "\n"
  printf "Adquira já (48) 99941-6725"

  printf "\n"
  printf "\n"
  printf "${NC}";

  sleep 30
}

system_certbot_erro_setup() {
  print_banner
  printf "${WHITE} 💻 Solicitando certificado...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  renovar_domain=$(echo "${renovar_url/https:\/\/}")

  sudo su - root <<EOF
  certbot -m cleitonme@gmail.com \
          --nginx \
          --agree-tos \
          --non-interactive \
          --domains $renovar_domain
EOF

  sleep 20
}

portainer_nginx_setup() {
  print_banner
  printf "${WHITE} 💻 Configurando nginx (portainer)...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  portainer_hostname=$(echo "${portainer_url/https:\/\/}")

sudo su - root << EOF

cat > /etc/nginx/sites-available/portainer << 'END'
server {
  server_name $portainer_hostname;
  
  location / {
    proxy_pass http://127.0.0.1:9000;
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

ln -s /etc/nginx/sites-available/portainer /etc/nginx/sites-enabled
EOF

  sleep 2
}

system_certbot_portainer_setup() {
  print_banner
  printf "${WHITE} 💻 Configurando certbot portainer...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  portainer_domain=$(echo "${portainer_url/https:\/\/}")

  sudo su - root <<EOF
  certbot -m cleitonme@gmail.com \
          --nginx \
          --agree-tos \
          --non-interactive \
          --domains $portainer_domain
EOF

  sleep 2
}

system_success_portainer() {

  print_banner
  printf "${GREEN} 💻 Instalação concluída...${NC}"
  printf "${CYAN_LIGHT}";
  printf "\n\n"
  printf "\n"
  printf "URL Portainer: https://$portainer_url"
  printf "\n"
  printf "\n"
  printf "${NC}";

  sleep 2
}

preparacao_migrar_docker() {
  print_banner
  printf "${WHITE} 💻 Removendo modelo antigo...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - deploy <<EOF
  pm2 delete all
  pm2 save

EOF

  sleep 2
}

Removido_Antigo() {

  print_banner
  printf "${GREEN} Pronto removemos modelo antigo...${NC}"
  printf "${CYAN_LIGHT}";
  printf "\n\n"
  printf "\n"
  printf "Agora pelo instalador use opção 2 para versão estavel ou 11 para versão beta"

  printf "\n"
  printf "\n"
  printf "${NC}";

  sleep 30
}

apagar_nao_usado() {
  print_banner
  printf "${WHITE} 💻 Apagando arquivos nao sera mais usados${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - root <<EOF
  cd /home/deploy/whazing/
  rm whazing.zip -Rf
  rm docs -Rf
  rm screenshots -Rf
  rm site -Rf
  cd /home/deploy/whazing/backend
  rm dist/ -Rf
  rm node_modules/ -Rf
  rm package.json -Rf
  rm package-lock.json -Rf
  cd /home/deploy/whazing/frontend  
  rm dist/ -Rf
  rm src/ -Rf
  rm node_modules/ -Rf
  rm package.json -Rf
  rm package-lock.json -Rf
EOF

  sleep 2
}

atualizacao_terminado() {

  print_banner
  printf "${GREEN} Pronto processo finalizado...${NC}"
  printf "${CYAN_LIGHT}";
  printf "\n\n"
  printf "\n"
  printf "Agora pode voltar usar sistema"

  printf "\n"
  printf "\n"
  printf "${NC}";

  sleep 30
}