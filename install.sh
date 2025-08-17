#!/bin/bash
# whazing_instalar_auto.sh
# Script para baixar o repositório e executar o instalador Whazing,
# salvando e restaurando o arquivo config

# Verifica se está como root
if [[ $EUID -ne 0 ]]; then
    echo "⚠️ Rode como root: sudo bash $0"
    exit 1
fi

# Atualiza sistema e instala dependências
echo "💻 Atualizando sistema e instalando dependências..."
apt update -y
apt install -y git software-properties-common

# Define diretório do instalador
INSTALL_DIR="/root/whazinginstalador"
CONFIG_FILE="$INSTALL_DIR/config"
BACKUP_FILE="/root/config_whazing_backup_$(date +%Y%m%d_%H%M%S)"

# Se a pasta existir, salva config antes de apagar
if [[ -d $INSTALL_DIR ]]; then
    echo "🗑️ Pasta '$INSTALL_DIR' já existe."
    
    if [[ -f $CONFIG_FILE ]]; then
        echo "💾 Salvando arquivo config antigo..."
        cp "$CONFIG_FILE" "$BACKUP_FILE"
        echo "✅ Config salvo em $BACKUP_FILE"
    fi
    
    echo "🗑️ Removendo pasta antiga..."
    rm -rf "$INSTALL_DIR"
fi

# Clona o repositório completo
echo "📂 Clonando repositório..."
git clone https://github.com/cleitonme/Whazing-SaaS.instalador.git "$INSTALL_DIR"

# Dá permissão de execução
chmod +x "$INSTALL_DIR/whazing"

# Restaura config antigo se existir
if [[ -f $BACKUP_FILE ]]; then
    echo "♻️ Restaurando arquivo config antigo..."
    cp "$BACKUP_FILE" "$CONFIG_FILE"
    echo "✅ Config restaurado em $CONFIG_FILE"
fi

# Executa o instalador interativo
echo "🚀 Iniciando instalador interativo..."
cd "$INSTALL_DIR" || exit
sudo bash whazing
