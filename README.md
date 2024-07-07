## CRIAR SUBDOMINIO E APONTAR PARA O IP DA SUA VPS

Requisitos

Ubuntu 20 com minimo 8GB memoria
2 dns do backend e do frontend


## CHECAR PROPAGAÇÃO DO DOMÍNIO

https://dnschecker.org/

## RODAR OS COMANDOS ABAIXO PARA INSTALAR

para evitar erros recomendados atualizar sistema e apos atualizar reniciar para evitar erros

```bash
apt -y update && apt -y upgrade
```
```bash
reboot
```
 
Depois reniciar seguir com a instalacao

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

## RODAR OS COMANDOS ABAIXO PARA ATUALIZAR

```bash
cd /root
```
```bash
cd ./whazinginstalador
```
```bash
sudo ./whazing
```

## Alterar Frontend

Para mudar nome do aplicativo:

/home/deploy/whazing/frontend/quasar.conf

/home/deploy/whazing/frontend/src/index.template.html

Para alterar logos e icones:

pasta /home/deploy/whazing/frontend/public

Para alterar cores:

/home/deploy/whazing/frontend/src/css/app.sass

/home/deploy/whazing/frontend/src/css/quasar.variables.sass

Sempre alterar usando usuario deploy você pode conectar servidor com aplicativo Bitvise SSH Client. Depois das alterações compilar novamente o Frontend

```bash
su deploy
```
```bash
cd /home/deploy/whazing/frontend/
```
```bash
npm run build
```

Testar as alterações em aba anonima

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

## Consultoria particular

Para consultoria particular chamar (será cobrado por isso) 48 999416725 

Versão api em bayles