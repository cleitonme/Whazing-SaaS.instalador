#!/bin/bash
set -e

echo "🚀 Iniciando instalador Whazing..."

# Atualiza pacotes e instala dependências
apt update -y
apt install -y software-properties-common git

# Caminho do instalador
INSTALL_DIR="/root/whazinginstalador"

# Clona ou atualiza repositório
if [ -d "$INSTALL_DIR/.git" ]; then
  echo "📥 Repositório já existe, atualizando..."
  # Faz backup do config
  if [ -f "$INSTALL_DIR/config" ]; then
    cp "$INSTALL_DIR/config" "$INSTALL_DIR/config.bak.$(date +%Y%m%d%H%M%S)"
    echo "💾 Backup do config criado"
  fi
  cd "$INSTALL_DIR"
  git pull --ff-only
else
  echo "📥 Clonando repositório..."
  cd /root
  git clone https://github.com/cleitonme/Whazing-SaaS.instalador.git whazinginstalador
  cd "$INSTALL_DIR"
fi

# Permissão de execução
chmod +x ./whazing

# Força execução interativa para abrir o menu corretamente
echo "⚙️ Abrindo menu interativo..."
exec bash -i -c "./whazing"
