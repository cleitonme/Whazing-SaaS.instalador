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

whazing_atualizar() {
  system_pm2_stop
  arruma_permissao
  apagar_distsrc
  git_update
  backend_node_dependencies
  backend_node_build
  backend_db_migrate
  system_pm2_start
  frontend_node_dependencies
  frontend_node_build
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

whazing_atualizar_beta() {
  system_pm2_stop
  arruma_permissao
  apagar_distsrc
  update_beta
  backend_node_dependencies
  backend_node_build
  backend_db_migrate
  system_pm2_start
  frontend_node_dependencies
  frontend_node_build
}

inquiry_options() {

  print_banner
  printf "\n\n"
  printf "${WHITE} 💻 O que você precisa fazer?${GRAY_LIGHT}"
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
      Recurso_Premium
      exit
      ;;
	  
    10) 
      Recurso_Premium
      exit
      ;;
	    
    11) 
      whazing_atualizar_beta
      exit
      ;;

    *) exit ;;
  esac
}

