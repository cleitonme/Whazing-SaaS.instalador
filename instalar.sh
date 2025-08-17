#!/bin/bash
set -e  # Sai em caso de erro

echo "🚀 Iniciando instalador Whazing..."

# Atualiza pacotes e instala dependências necessárias
apt update -y
apt install -y software-properties-common git

# Caminho do instalador
INSTALL_DIR="/root/whazinginstalador"

# Se a pasta já existe
if [ -d "$INSTALL_DIR/.git" ]; then
  echo "📥 Repositório já existe, atualizando..."

  # Faz backup do arquivo config, se existir
  if [ -f "$INSTALL_DIR/config" ]; then
    BACKUP_FILE="$INSTALL_DIR/config.bak.$(date +%Y%m%d%H%M%S)"
    cp "$INSTALL_DIR/config" "$BACKUP_FILE"
    echo "💾 Backup do config criado em $BACKUP_FILE"
  fi

  # Atualiza repositório sem sobrescrever arquivos locais
  cd "$INSTALL_DIR"
  git pull --ff-only
else
  echo "📥 Clonando repositório pela primeira vez..."
  cd /root
  git clone https://github.com/cleitonme/Whazing-SaaS.instalador.git whazinginstalador
  cd "$INSTALL_DIR"
fi

# Dá permissão de execução ao instalador
chmod +x ./whazing

# Executa o instalador principal
echo "⚙️ Executando instalador..."
./whazing

echo "✅ Instalação/atualização concluída!"
