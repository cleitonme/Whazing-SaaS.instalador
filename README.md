[![Grupo do WhatsApp](https://img.shields.io/badge/WhatsApp-Grupo%20Whazing-brightgreen.svg)](https://grupo.whazing.com.br)

# Whazing SaaS

Manual do produto

[https://doc.whazing.com.br/](https://doc.whazing.com.br/)

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
curl -sSL instalar.whazing.com.br | sudo bash
```

## Manual de como atualizar

[https://doc.whazing.com.br/atualizar-whazing](https://doc.whazing.com.br/atualizar-whazing) 

**IMPORTANTE**: 

- [Termos de Uso](https://doc.whazing.com.br/termos-de-uso-da-plataforma)
- [Contrato de Licença](https://doc.whazing.com.br/contrato-de-licenca-de-uso-de-software)


Versão Grátis 🆓

Exibe anúncios do Whazing.

Envia automaticamente propaganda em:
• Primeira mensagem de novos tickets
• Mensagens via API
• Mensagens agendadas
• Follow-ups

Versão Premium 💎

Sem anúncios.

Entregas limpas, sem propaganda adicional.


-  [Tabela de Valores versão premium e serviço de instalação](https://doc.whazing.com.br/tabela-de-valores)


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