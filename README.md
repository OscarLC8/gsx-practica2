# Setmana 8: Contenidorització amb docker

En aquesta documentació s'explica el procés de contenidorització de les dues aplicacions requerides a la setmana 8: servidor Nginx i una aplicació backend. 

## 1. Contenidor Nginx: Servidor web

L'objectiu d'aquest contenidor és posar com a servei una pàgina web funcional en qualsevol entorn. Per fer-ho, s'ha hagut de sobreescriure la configuració per defecte.

### 1.1. Explicació dockerfile i justificació de la imatge base
L'arxiu Dockerfile s'ha fet amb les següents instruccions:

`FROM nginx:latest`: En aquesta instrucció s'ha escollit la imatge oficial i més recent de Nginx (requisit directe de la pràctica). Aquesta imatge base ens proporciona estabilitat i facilitat d'instal·lació i configuració, ja que porta el motor web preinstal·lat.

`COPY ./default.conf /etc/nginx/conf.d/default.conf`: En aquesta instrucció es on es posa la nostra configuració personalitzada.

`COPY ./html /usr/share/nginx/html`: En aquesta comanda s'han copiat els nostres arxius funcionals per a mostrar la pàgina web a la ruta corresponent per defecte per Nginx.

### 1.2. Dependències
Per a poder construir la imatge del contenidor, al directori local es requereix dels següents items:

- Fitxer *default.conf* (configurat per a escoltar per al port 80).
- Carpeta *html/* amb els fitxers web.

### 1.3. Construcció i execució del contenidor
Per a construir i provar la imatge, s'han utilitzat les següents comandes en ordre:

1. Construir imatge:

`docker build -t nginx-gsx .`

2. Executar contenidor mapejant port 80:

`docker run -p 80:80 nginx-gsx`

3. Comprovació:
 
`curl localhost`


---


## 2. Contenidor de l'aplicació backend

Aquesta aplicació és l'encarregada de respondre peticions HTTP bàsiques.

### 2.1. Explicació dockerfile i justificació de la imatge base
L'arxiu Dockerfile.app s'ha fet amb les següents instruccions:

`FROM python:3.9-slim`: En aquest cas s'ha optat per una imatge slim. S'ha pres aquesta decisió perquè, al utilitzar aquesta imatge, es redueix molt l'espai d'emmagatzematge, i per tant, la superfície d'algún possible atac.

`COPY app.py .`: Aquesta comanda introdueix l'script al contenidor.

`CMD ["python", "app.py"]`: Es defineix la comanda per defecte que s'executarà quan s'arrenqui el contenidor.

### 2.2. Dependències
Aquesta imatge únicament depèn de que l'arxiu app.py estigui inclòs al repositori. Aquest arxiu app.py obre un servidor HTTP al port 3000. Per saber si s'ha iniciat correctament, retorna un missatge "Hello from container".

### 2.3. Construcció i execució del contenidor

Per a construir i provar la imatge, s'han utilitzat les següents comandes en ordre:

1. Construir imatge:

`docker build -t app-simple -f Dockerfile.app .` (En aquest cas cal indicar el nom de l'arxiu, sino utilitzaria Dockerfile per defecte)

2. Executar contenidor mapejant port 3000:

`docker run -p 3000:3000 app-simple`

3. Comprovació:

`curl localhost:3000`


---


## 3. Publicació a Docker Hub

Per assegurar que la nostra infratestructura es pot desplegar i executar des de qualsevol sistema o dispositiu, s'han publicat les imatges al registre públic de Docker Hub.
Per fer-ho, s'han executat les següents comandes en ordre:

1. Autenticar-se al sistema:

`docker login`

2. Tagging vinculat a la imatge local amb l'usuari de Docker Hub

`docker tag nginx-gsx nom_usuari/nginx-gsx:v1`
`docker tag app-simple nom_usuari/app-simple:v1`

3. Push al repositori remot:

`docker push nom_usuari/nginx-gsx:v1`
`docker push nom_usuari/app-simple:v1`

4. Per a descarregar-lo en un equip de proves:

`docker pull nom_usuari/nginx-gsx:v1`


---


## 4. Decisions de disseny i seguretat

1. Mapeig de ports: S'han separat els ports utilitzats per a evitar possibles problemes i col·lisions, emprant el port 80 per l'Nginx i el port 3000 per l'aplicacioó backend.

2. Optimització d'imatges: S'ha utilitzat la versió *slim* per a reduir dràsticament l'ús de recursos i per qüestions també de seguretat.
