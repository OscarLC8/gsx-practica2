# gsx-practica2
#Setmana 9: Orquestració Multi-Contenidor (Docker Compose)
En aquesta fase de la infraestructura, hem evolucionat de contenidors individuals a un entorn orquestrat localment mitjançant Docker Compose. Això ens permet definir, configurar i executar múltiples serveis interconnectats mitjançant un únic arxiu de configuració.

##1. Diagrama d'Arquitectura
El següent diagrama il·lustra l'arquitectura de la nostra aplicació multi-contenidor i com flueixen les connexions entre els diferents elements:
 
                                    +------------------------+
                                    |  Xarxa Interna Docker  |
                                    |                        |
                                    |                        |
     [Usuari/Navegador]             |    +--------------+    |
             |                      |    |   Service:   |    |
             | HTTP (Port dinàmic)  |    |   backend    |    |
             |                      |    | (Python App) |    |
     +----------------+             |    +--------------+    |
     |    Service:    |             |           ^            |
     |     nginx      | -depends-on-+           |            |
     |  (Web Server)  | ---------------(http://backend:3000)-+
     +----------------+
             |
             | Mapeig de Volums
             |
     +----------------+
     |     Volum      |
     |   nginx_data   |
     +----------------+

##2. Explicació dels Serveis
El nostre arxiu 'docker-compose.yml'orquestra els serveis següents
###Servei nginx (web-nginx):
Actua com el servidor web principal. Es construeix a partir d'un 'Dockerfile' que utilitza la imatge base 'nginx:latest' i incorpora els nostres arxius HTML i configuració personalitzada. Hem implementat la directiva 'depends_on: - backend' (Nivell Intermedi), la qual cosa assegura que el servidor web no s'iniciï fins que l'API (backend) estigui a punt per rebre peticions.

###Servei backend (python-backend):
És una aplicació Python senzilla construïda sobre la imatge 'python:3.9-slim'. Executa l'arxiu 'app.py', aixecant un servidor HTTP al port 3000 que respon amb el missatge "Hello from container".  

###Xarxes (Networking):
En desplegar amb Compose, ambdós contenidors s'agrupen en una mateixa xarxa interna per defecte. Això ens permet delegar la resolució DNS a Docker, de manera que el servei Nginx pot comunicar-se amb l'aplicació Python simplement apuntant a l'URL 'http://backend:3000', sense necessitat de codificar IPs estàtiques.

##3. Persistència de Dades (Volums)
Els contenidors són entorns efímers per naturalesa. Si un contenidor es reinicia o es destrueix, totes les dades generades al seu interior es perden.  

Per solucionar això i garantir la resiliència de les dades, hem implementat el següent:  

###Volum 'nginx_data':
Hem declarat aquest volum al Compose i l'hem mapejat al directori '/usr/share/nginx/html' del contenidor Nginx.
###Justificació:
Això assegura que els arxius estàtics de la pàgina web persisteixin i sobrevisquin a qualsevol cicle de reinici del contenidor, separant el cicle de vida de l'aplicació del cicle de vida de l'emmagatzematge.

##4. Gestió de la Configuració i Seguretat (Secrets)
Per complir amb les millors pràctiques de seguretat i evitar el hardcoding (incrustació estàtica) de configuració, hem dissenyat l'estratègia següent:

###Variables d'Entorn:
Els ports dels nostres serveis no estan escrits directament al codi. A l'arxiu 'docker-compose.yml' utilitzem variables com '${NGINX_PORT}:80' i '${BACKEND_PORT}:3000'.

###Arxiu .env i .gitignore:
Els valors reals d'aquestes variables es defineixen en un arxiu local anomenat '.env'. Aquest arxiu ha estat exclòs del control de versions afegint-lo al '.gitignore', garantint que cap configuració sensible o secret es filtri al repositori públic.

###Arxiu .env.example:
Hem generat una plantilla d'exemple amb els mateixos valors perquè qualsevol membre de l'equip sàpiga quines variables necessita configurar en clonar el projecte.  

##5. Proves de Funcionament (Testing)
Hem validat el funcionament correcte de la infraestructura mitjançant la bateria de proves de cicle de vida següent:

###Desplegament:
Execució de 'docker-compose up -d' i verificació de l'estat amb 'docker-compose ps' per assegurar que ambdós serveis estan aixecats ("Up").

###Comunicació Interna
Accés al contenidor web i execució de la comanda 'curl http://backend:3000'. La resposta rebuda és "Hello from container", la qual cosa demostra la perfecta comunicació interna.

###Comprovació del Volum:
Després d'apagar i destruir la infraestructura amb 'docker-compose down', l'execució de 'docker volume ls' confirma que el volum 'nginx_data' segueix existint intacte.
