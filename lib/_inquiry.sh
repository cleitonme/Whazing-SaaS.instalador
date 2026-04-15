#!/bin/bash

get_frontend_url() {
  print_banner
  printf "${WHITE} 💻 Digite o domínio da interface web (Frontend):${GRAY_LIGHT}\n\n"
  read -p "> " frontend_url </dev/tty
}

get_backend_url() {
  print_banner
  printf "${WHITE} 💻 Digite o domínio da sua API (Backend):${GRAY_LIGHT}\n\n"
  read -p "> " backend_url </dev/tty
}

get_urls() {
  get_frontend_url
  get_backend_url
}

get_renovar_url() {
  print_banner
  printf "${WHITE} 💻 Digite o domínio com erro SSL:${GRAY_LIGHT}\n\n"
  read -p "> " renovar_url </dev/tty
}

get_portainer_url() {
  print_banner
  printf "${WHITE} 💻 Digite o domínio do Portainer:${GRAY_LIGHT}\n\n"
  read -p "> " portainer_url </dev/tty
}

whazing_atualizar() {
  download_docker_imagem_estavel
  backend_docker_remove
  backend_docker_start
  frontend_docker_start
  limpa_docker_imagem
  atualizacao_terminado
}

ativar_firewall () {
  iniciar_firewall
}

desativar_firewall () {
  parar_firewall
}

Erro_global () {
  erro_banco
}

Portainer_ssl () {
  get_portainer_url
  portainer_nginx_setup
  system_nginx_restart
  system_certbot_portainer_setup
  system_success_portainer
}

whazing_atualizar_beta() {
  download_docker_imagem_beta
  backend_docker_remove
  backend_docker_update_beta
  frontend_docker_update_beta
  limpa_docker_imagem
  atualizacao_terminado
}

Erro_ssl () {
  get_renovar_url
  system_certbot_erro_setup
}

atualizar_ponteiner () {
  ponteiner_docker_update
}

migrar_docker () {
  preparacao_migrar_docker
  apagar_nao_usado
  instalacao_firewall
  criar_cron
  Removido_Antigo
}

inquiry_options() {

  print_banner
  printf "\n\n"
  printf "${WHITE} 💻 O que você precisa fazer?${GRAY_LIGHT}\n\n"
  printf "   Versão instalador 15/04/2026\n\n"
  printf "   [1] Instalar\n"
  printf "   [2] Atualizar whazing(antes de atualizar faça um Snapshots da VPS\n"
  printf "   [3] Atualizar whazing BETA(antes de atualizar faça um Snapshots da VPS\n"
  printf "   [4] Ativar Firewall\n"
  printf "   [5] Desativar Firewall\n"
  printf "   [6] Erro global/pg_filenode.map\n"
  printf "   [7] Migração instalação antiga(para quem instalou sistema antes 19/05/25)\n"
  printf "   [8] Atualizar o ponteiner\n\n"

  read -p "> " option </dev/tty

  case "${option}" in
    1) 
      get_urls

      # Verifica timezone só na instalação
      echo "⏰ O timezone atual configurado é: $timezonetext ($timezonenumber)"
      read -p "Está correto? (s/n) " resposta </dev/tty

      if [[ "$resposta" =~ ^[Nn]$ ]]; then
          echo "Digite o novo timezone (exemplo: America/Sao_Paulo):"
          read -p "> " novo_timezone </dev/tty

          echo "Digite o número da timezone (exemplo: -03:00):"
          read -p "> " novo_timezonenumber </dev/tty

          # Atualiza arquivo config
          sed -i "s|^timezonetext=.*|timezonetext=${novo_timezone}|" "${PROJECT_ROOT}"/config
          sed -i "s|^timezonenumber=.*|timezonenumber=${novo_timezonenumber}|" "${PROJECT_ROOT}"/config

          # Atualiza variáveis na sessão atual
          timezonetext=$novo_timezone
          timezonenumber=$novo_timezonenumber

          echo "✅ Timezone atualizado para: $timezonetext ($timezonenumber)"
          sleep 1
      fi
      ;;

    2) 
      whazing_atualizar 
      exit
      ;;

    3) 
      whazing_atualizar_beta
      exit
      ;;

    4) 
      ativar_firewall 
      exit
      ;;
	  
    5) 
      desativar_firewall 
      exit
      ;;
	  
    6) 
      Erro_global 
      exit
      ;;
	 
    7) 
      migrar_docker
      exit
      ;;

    8) 
      atualizar_ponteiner
      exit
      ;;

    *) exit ;;
  esac
}
