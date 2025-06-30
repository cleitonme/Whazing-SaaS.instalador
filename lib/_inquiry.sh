#!/bin/bash

get_frontend_url() {
  print_banner
  printf "${WHITE} 💻 Digite o domínio da interface web (Frontend):${GRAY_LIGHT}"
  printf "\n\n"
  read -p "> " frontend_url
}

get_backend_url() {
  print_banner
  printf "${WHITE} 💻 Digite o domínio da sua API (Backend):${GRAY_LIGHT}"
  printf "\n\n"
  read -p "> " backend_url
}

get_urls() {
  get_frontend_url
  get_backend_url
}

get_renovar_url() {
  print_banner
  printf "${WHITE} 💻 Digite o domínio com erro SSL:${GRAY_LIGHT}"
  printf "\n\n"
  read -p "> " renovar_url
}

get_portainer_url() {
  print_banner
  printf "${WHITE} 💻 Digite o domínio do Portainer:${GRAY_LIGHT}"
  printf "\n\n"
  read -p "> " portainer_url
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
  printf "${WHITE} 💻 O que você precisa fazer?${GRAY_LIGHT}"
  printf "\n\n"
  printf "   Versão 30/05/2025 - 11:12\n"
  printf "\n\n"
  printf "   [1] Instalar\n"
  printf "   [2] Atualizar whazing(antes de atualizar faça um Snapshots da VPS\n"
  printf "   [3] Ativar Firewall\n"
  printf "   [4] Desativar Firewall\n"
  printf "   [5] Erro global/pg_filenode.map\n"
  printf "   [6] Instalar N8N - necessario 1 dominio\n"
  printf "   [7] Instalar TypeBot - necessario 4 dominios\n"
  printf "   [8] Instalar Wordpress - necessario 1 dominio\n"
  printf "   [9] Dominio com erro SSL\n"
  printf "   [10] Liberar acesso portainer dominio SSL - necessario 1 dominio\n"
  printf "   [11] Atualizar whazing BETA(antes de atualizar faça um Snapshots da VPS\n"
  printf "   [12] Migração instalação antiga(para quem instalou sistema antes 19/05/25)\n"
  printf "   [13] Atualizar o ponteiner\n"
  printf "\n"
  read -p "> " option

  case "${option}" in
    1) get_urls ;;


    2) 
      whazing_atualizar 
      exit
      ;;


    3) 
      ativar_firewall 
      exit
      ;;
	  
    4) 
      desativar_firewall 
      exit
      ;;
	  
    5) 
      Erro_global 
      exit
      ;;
	  
    6) 
      Recurso_Premium
      exit
      ;;
	  
    7) 
      Recurso_Premium
      exit
      ;;
	  
    8) 
      Recurso_Premium
      exit
      ;;

    9) 
      Erro_ssl
      exit
      ;;
	  
    10) 
      Portainer_ssl
      exit
      ;;
	    
    11) 
      whazing_atualizar_beta
      exit
      ;;

    12) 
      migrar_docker
      exit
      ;;

    13) 
      atualizar_ponteiner
      exit
      ;;

    *) exit ;;
  esac
}

