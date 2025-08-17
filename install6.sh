#!/bin/bash
# whazing_auto_install.sh
# Script para baixar e iniciar instalador interativo Whazing

# Verifica se está como root
if [[ $EUID -ne 0 ]]; then
    echo "⚠️ Rode como root: sudo bash $0"
    exit 1
fi

# Atualiza sistema e instala dependências
echo "💻 Atualizando sistema e instalando dependências..."
apt update -y && apt upgrade -y
apt install -y git software-properties-common

# Baixa repositório do instalador
INSTALL_DIR="/root/whazinginstalador"
if [[ -d $INSTALL_DIR ]]; then
    echo "🗑️ Pasta $INSTALL_DIR já existe, removendo..."
    rm -rf "$INSTALL_DIR"
fi

echo "📂 Clonando repositório..."
git clone https://github.com/cleitonme/Whazing-SaaS.instalador.git "$INSTALL_DIR"

# Dá permissão de execução
chmod +x "$INSTALL_DIR/whazing"

# Executa o instalador interativo **no mesmo terminal**
echo "🚀 Iniciando instalador interativo..."
cd "$INSTALL_DIR" || exit
sudo ./whazing
