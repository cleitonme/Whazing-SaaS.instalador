sudo apt install -y tmux git
cd /root
git clone https://github.com/cleitonme/Whazing-SaaS.instalador.git whazinginstalador
chmod +x whazinginstalador/whazing
tmux new-session -d -s whazing './whazing; bash'
tmux attach -t whazing
