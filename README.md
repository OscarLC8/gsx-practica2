# gsx-practica2
# Documentació Setmana 10: Orquestració amb Kubernetes
Aquesta secció documenta l'arquitectura i les decisions preses durant la migració de la nostra aplicació a Kubernetes, amb l'objectiu de garantir l'escalabilitat automàtica, la recuperació davant d'errors i l'alta disponibilitat.

## 1. Explicació dels Recursos de Kubernetes
Per dur a terme aquest desplegament, hem utilitzat tres tipus de recursos fonamentals de Kubernetes:

### ConfigMap (Configuració):
És un objecte que emmagatzema dades de configuració en format clau-valor (com per exemple `BACKEND_PORT=3000` i `NGINX_PORT=80`). Aquest recurs és necessari perquè ens permet separar la configuració del codi de l'aplicació. Gràcies a això, podem canviar els ports o les variables d'entorn sense haver de tornar a construir (build) les imatges de Docker.

### Deployment (Desplegament):
És el controlador que defineix l'estat desitjat de les nostres aplicacions (per exemple, establir que hi hagi 1 instància de Python i 1 d'Nginx funcionant amb imatges concretes). Aquest recurs aporta la resiliència necessària (Self-healing). Si un contenidor (Pod) s'espatlla, Kubernetes ho detecta i en crea un de nou automàticament per mantenir l'estat desitjat. A més, permeten fer actualitzacions de versió sense talls de servei.

### Service (Servei):
És un punt d'accés de xarxa estable que agrupa un conjunt de Pods. A Kubernetes, els Pods són efímers i les seves adreces IP canvien constantment. Necessitem el Service perquè proporciona un nom de domini fix (DNS) i una IP estable, permetent que la resta del sistema pugui trobar l'aplicació sense preocupar-se de l'adreça IP específica del Pod en aquell moment.

---

## 2. Xarxes i Comunicació
L'arquitectura de xarxa defineix com interactuen els components internament i com s'exposen a l'exterior:

### Comunicació interna entre Pods:
Els Pods es comuniquen utilitzant el servei de DNS intern que porta integrat Kubernetes. Quan el servei Nginx vol comunicar-se amb el backend en Python, no necessita saber la seva IP física. Simplement fa una petició a `http://backend:3000`. El DNS de Kubernetes tradueix el nom "backend" cap a la IP estable del Service, i aquest s'encarrega d'enviar el trànsit cap a un Pod de Python que estigui disponible.

### Accés de clients externs:
En el nostre desplegament, hem utilitzat Services de tipus `ClusterIP`, els quals són privats i només accessibles des de dins del clúster per garantir la màxima seguretat. Perquè un client extern pugui accedir a l'aplicació des d'internet, el procediment requeriria canviar el Service a tipus `NodePort` (que obre un port públic a les màquines) o `LoadBalancer`, o bé configurar un objecte `Ingress` que faci d'embut per rebre el trànsit extern i enrutar-lo correctament cap a l'interior.

--- 

## 3. Comportament de l'Escalabilitat (Scaling)
Hem comprovat i documentat com Kubernetes gestiona l'escalabilitat dinàmica.

### Execució de l'escalat:
Vam aplicar la comanda `kubectl scale deployment nginx --replicas=3` per augmentar el nombre d'instàncies.  

### Gestió de l'estat desitjat:
En llançar aquesta comanda, es modifica l'estat desitjat del Deployment. El controlador de Kubernetes detecta que només tenim 1 Pod funcionant, però l'estat requerit és de 3. Com a resposta, programa i crea 2 Pods nous automàticament.

### Repartiment de càrrega:
Un cop aquests nous Pods estan llestos, el recurs Service de l'Nginx els afegeix automàticament a la seva llista interna de resolució. A partir d'aquell moment, qualsevol petició es reparteix equitativament entre els 3 Pods (Load Balancing), evitant la saturació d'una única instància durant pics de trànsit.

---

## 4. Resolució de Problemes (Troubleshooting)
Durant la fase d'implementació vam documentar la resolució de la següent incidència:

### Problema:
Aparició de l'error `ImagePullBackOff` en intentar aixecar els Pods.

### Diagnòstic:
Utilitzant la comanda de diagnòstic de Pods, vam determinar que Kubernetes no trobava la imatge associada. Això va ser causat per una càrrega incorrecta al Docker Hub o per un error de sintaxi al manifest YAML.

### Solució:
Es va solucionar estandarditzant el nom d'usuari a les configuracions, generant un nou `docker build`, i verificant que l'acció de `docker push` s'havia completat correctament cap al registre remot abans de tornar a aplicar els manifests al clúster de Kubernetes.


