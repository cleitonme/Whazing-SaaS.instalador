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
git clone https://github.com/cleitonme/izingpro.bayles.install.git izinginstalador
```
```bash
sudo chmod +x ./izinginstalador/izing
```
```bash
cd ./izinginstalador
```
```bash
sudo ./izing
```

## RODAR OS COMANDOS ABAIXO PARA ATUALIZAR

```bash
cd /root
```
```bash
cd ./izinginstalador
```
```bash
sudo ./izing
```

## Alterar Frontend

Para mudar nome do aplicativo:

/home/deploy/izing/frontend/quasar.conf

/home/deploy/izing/frontend/src/index.template.html

Para alterar logos e icones:

pasta /home/deploy/izing/frontend/public

Para alterar cores:

/home/deploy/izing/frontend/src/css/app.sass

/home/deploy/izing/frontend/src/css/quasar.variables.sass

Sempre alterar usando usuario deploy você pode conectar servidor com aplicativo Bitvise SSH Client. Depois das alterações compilar novamente o Frontend

```bash
su deploy
```
```bash
cd /home/deploy/izing/frontend/
```
```bash
npm run build
```

Testar as alterações em aba anonima

## Erros

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

## Consultoria particular

Para consultoria particular chamar (será cobrado por isso) 48 999416725 

Versão api em bayles