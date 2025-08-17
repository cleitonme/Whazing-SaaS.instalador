sudo su -

# Vai para /root
cd /root

# Se a pasta já existir, remove ou atualiza
if [[ -d whazinginstalador ]]; then
    echo "🗑️ Pasta 'whazinginstalador' já existe, removendo..."
    rm -rf whazinginstalador
fi

# Clona o repositório completo
git clone https://github.com/cleitonme/Whazing-SaaS.instalador.git whazinginstalador

# Dá permissão de execução
chmod +x whazinginstalador/whazing

# Entra na pasta e executa o instalador interativo
cd whazinginstalador
./whazing
