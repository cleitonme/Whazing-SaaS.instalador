#!/bin/bash
# whazing_install.sh
# Script para instalar Whazing em um único comando

# Verifica se está como root
if [[ $EUID -ne 0 ]]; then
   echo "⚠️ Por favor rode como root: sudo bash $0"
   exit 1
fi

echo "💻 Atualizando sistema..."
apt update -y

echo "📦 Instalando dependências..."
apt install -y git software-properties-common

echo "📂 Baixando repositório do instalador..."
cd /root || exit
if [[ -d whazinginstalador ]]; then
    echo "🗑️ Pasta whazinginstalador já existe, removendo..."
    rm -rf whazinginstalador
fi

git clone https://github.com/cleitonme/Whazing-SaaS.instalador.git whazinginstalador

echo "🔧 Dando permissão para o instalador..."
chmod +x whazinginstalador/whazing

echo "🚀 Iniciando instalador interativo..."
cd whazinginstalador || exit
./whazing
