#!/bin/bash
# Atualiza sistema
apt update -y && apt upgrade -y
apt install -y software-properties-common git

# Baixa o instalador
curl -sSL https://raw.githubusercontent.com/cleitonme/Whazing-SaaS.instalador/main/whazing -o /tmp/whazing
chmod +x /tmp/whazing

# Executa interativo
sudo /tmp/whazing
