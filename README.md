[![Grupo do WhatsApp](https://img.shields.io/badge/WhatsApp-Grupo%20Whazing-brightgreen.svg)](https://grupo.whazing.com.br)

# Whazing SaaS

**IMPORTANTE**: 

- [Termos de Uso](https://github.com/cleitonme/Whazing-SaaS/blob/main/docs/TermosdeUso.md)
- [Contrato de Licença](https://github.com/cleitonme/Whazing-SaaS/blob/main/LICENSE)

Versão grátis*

- Limites da versão grátis 
- 10 usuários
- 2 canais
- Suporte WhatsApp Api Bayles
- Suporte facebook e Instagram  e WebChat - VIA HUB - Necessario pagar mensalidade por canal duvidas (48) 9941-6725
- Suporte Telegram
- Verificar premium abaixo para saber diferenças

Versão Premium*

- Sem limites de usuários e canais
- Kanban
- Integração WebHook/N8N - TypeBot - Groq - ChatGPT - DeepSeek
- Transcrição de audio
- Tarefas
- Avaliação de atendimento
- Geração PDF atendimento
- Relatorio de tickets
- Anotações em tickets
- Mensagens separadas por filas
- Transferir atendimento para ChatBot
- Retirada mensagem "Enviado via Whazing" no modulo campanhas

- Instalador versão premium TypeBot, N8N e Wordpress


-  [Tabela de Valores versão premium e serviço de instalação](https://github.com/cleitonme/Whazing-SaaS/blob/main/docs/TabeladeValores.md)

## CRIAR SUBDOMINIO E APONTAR PARA O IP DA SUA VPS

Requisitos

Ubuntu 20 com minimo 8GB memoria
2 dns do backend e do frontend


### Checar Propagação do Domínio

Utilize [dnschecker.org](https://dnschecker.org/) para verificar a propagação.

- Caso use cloudflare não ativar proxy(nuvem laranja)
- Ao verificar dnschecker.org deve aparecer ip da sua vps somente em todas validações

## RODAR OS COMANDOS ABAIXO PARA INSTALAR

Para evitar erros, recomenda-se atualizar o sistema e reiniciar antes da instalação:

```bash
sudo su root
```

```bash
apt install software-properties-common
```

```bash
apt -y update && apt -y upgrade
reboot
```
 
Depois reniciar seguir com a instalacao
```bash
sudo su root
```
```bash
apt install git
```
```bash
cd /root
```
```bash
git clone https://github.com/cleitonme/Whazing-SaaS.instalador.git whazinginstalador
```
```bash
sudo chmod +x ./whazinginstalador/whazing
```
```bash
cd ./whazinginstalador
```

```bash
sudo ./whazing
```

## RODAR OS COMANDOS ABAIXO PARA ATUALIZAR O ATUALIZADOR

1 - acessar como root
```bash
sudo su root
```

2 - acessar pasta root
```bash
cd /root/
```


3 - apagar instalador antigo
```bash
rm whazinginstalador/ -Rf
```

4 - baixar novo instalador
```bash
git clone https://github.com/cleitonme/Whazing-SaaS.instalador.git whazinginstalador
```

5 - Da permisão
```bash
sudo chmod +x ./whazinginstalador/whazing
```

6 - Acessar pasta
```bash
cd ./whazinginstalador
```

8 - Executar
```bash
./whazing
```

## RODAR OS COMANDOS ABAIXO PARA ATUALIZAR
```bash
sudo su root
```
```bash
cd /root
```
```bash
cd ./whazinginstalador
```
```bash
chmod +x whazing
```
```bash
sudo ./whazing
```

## Alterar Frontend

Use configuração do Menu empresas para alterar nome do site e LOGOS 

## Erros

Caso não inicie na primeira instalação use opção 2 para atualizar pode ser algum arquivo não baixou corretamente

"Internal server error: SequelizeConnectionError: could not open file \"global/pg_filenode.map\": Permission denied"

```bash
docker container restart postgresql
```
```bash
docker exec -u root postgresql bash -c "chown -R postgres:postgres /var/lib/postgresql/data"
```
```bash
docker container restart postgresql
```

## Acesso Portainer gerar senha
"Your Portainer instance timed out for security purposes. To re-enable your Portainer instance, you will need to restart Portainer."

```bash
docker container restart portainer
```

Depois acesse novamente url http://seuip:9000/

## Recomendação de VPS boa e barata

-  [Powerful cloud VPS & Web hosting.](https://control.peramix.com/?affid=58)

- Cupom 25% desconto "WHAZING"

```bash
WHAZING
```

#### Curtiu? Apoie o projeto!! Com sua doação, será possível continuar com as atualizações. Segue QR code (PIX)  

[<img src="donate.jpg" height="160" width="180"/>](donate.jpg)

## Consultoria particular

Para consultoria particular (serviço cobrado), entre em contato: (48) 99941-6725.

Versão api em bayles