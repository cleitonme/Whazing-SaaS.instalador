# Antes de começar faça um snapshot da VPS  #

# Tutorial rapido e facil de como migrar nova versão

## RODAR OS COMANDOS ABAIXO ANTES FAÇA BACKUP DA VPS

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

9 - Usar opção 12 instalador para remover modelo antigo

10 - Abra instalador novamente
```bash
./whazing
```

11 - Use opção 2 para versão estavel ou 11 versão beta