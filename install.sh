#!/bin/bash
# Atualiza o sistema
apt update -y

# Instala dependências
apt install -y software-properties-common git

# Vai para a pasta /root
cd /root || exit

# Clona o instalador
git clone https://github.com/cleitonme/Whazing-SaaS.instalador.git whazinginstalador

# Dá permissão de execução
chmod +x ./whazinginstalador/whazing

# Executa o instalador interativo
cd ./whazinginstalador || exit
./whazing
