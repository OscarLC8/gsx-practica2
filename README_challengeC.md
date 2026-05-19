## Repte C: Documentació del Sistema

### 1. Diagrama d'Arquitectura i Flux de Dades
*Aquest diagrama en ASCII mostra l'arquitectura de GreenDevCorp i els fluxos de dades principals:*
```text
[Client Extern (Navegador/Professor)]
                         │
                         ▼ (Port Públic de Minikube / Ingress)
┌────────────────────────────────────────────────────────┐
│ Clúster de Kubernetes (Minikube) Namespace: default    
│                                                        
│  ┌──────────────────────────────────────────────────┐  
│  │ SERVEI NGINX (Port 80)                           
│  │ (Service tipus ClusterIP / NodePort)             
│  └───────────────────────┬──────────────────────────┘  
│                          │                             
│                          ▼ (Trànsit de Proxy Intern)   
│                 http://backend:3000                    
│                          │                             
│  ┌───────────────────────▼──────────────────────────┐  
│  │ SERVEI BACKEND (Port 3000)                       
│  │ (Service tipus ClusterIP)                      
│  └───────────────────────┬──────────────────────────┘  
│                          │                             
│                          ▼ (Resolució de DNS Intern)   
│  ┌──────────────────────────────────────────────────┐  
│  │ PODS EN EXECUCIÓ                                
│  │  ├─ [Pod: web-nginx] (Imatge local ARM64)      
│  │  └─ [Pod: python-backend] (Imatge local ARM64)     
│  └──────────────────────────────────────────────────┘  
│                          ▲                             
│                          │ (Injecta Variables)         
│               ┌──────────┴──────────┐                  
│               │ ConfigMap                             
│               │ (gsx-config)                     
│               └─────────────────────┘                  
└────────────────────────────────────────────────────────┘
```
**Descripció dels fluxos de dades:**
El trànsit extern arriba al clúster i és rebut pel Servei de l'Nginx. L'Nginx actua com a proxy invers ("reverse proxy"). Quan rep una petició web, en lloc de processar-la ell mateix, obre una connexió interna cap a l'adreça `http://backend:3000`. El component de DNS intern de Kubernetes tradueix automàticament el nom "backend" cap a la IP estable del Servei de Python, el qual finalment desvia el trànsit cap al Pod del backend que estigui lliure per retornar la resposta.

### 2. Documentació dels Components
**Component 1: Frontal Web (`web-nginx`)**
- **Què fa:** Actua com a portal d'entrada de l'empresa GreenDevCorp. Rep les peticions dels clients i gestiona l'encaminament cap al servidor d'aplicacions.

- **Dependències:** Depèn completament de la disponibilitat del servei "backend" i del ConfigMap per conèixer el port correcte.

- **Com es desplega:** Mitjançant un Deployment de Kubernetes definit a Terraform amb 1 rèplica.

- **Com es configura:** Es configura injectant el fitxer de definició de rutes `default.conf` de Nginx i utilitza la política `image_pull_policy = Never` per garantir l'ús del binari local de la màquina virtual.


**Component 2: Servidor d'Aplicacions (`python-backend`)**
- **Què fa:** Executa l'script de Python (`app.py`) que conté la lògica de negoci del projecte.

- **Dependències:** Cap dependència externa directa en aquesta fase.

- **Com es desplega:** Mitjançant un Deployment de Kubernetes gestionat de forma automatitzada per Terraform.

- **Com es configura:** La seva configuració és totalment dinàmica gràcies al ConfigMap global de l'entorn (`gsx-config`), el qual li passa la variable d'entorn `BACKEND_PORT` establerta al port 3000.

### 3. Runbook Operacional (Operational Runbook)
**Com desplegar una nova versió de l'aplicació:**
1. Modificar el codi de l'aplicació o de l'Nginx a la carpeta `docker-compose/`.
2. Tornar a compilar la imatge actualitzant l'etiqueta de la versió directament a Minikube:
`minikube image build -t oscarlopezgsx/app-simple:v2 -f Dockerfile.app`
3. Canviar la versió de la imatge al fitxer `main.tf` de Terraform.
4. Aplicar els canvis per fer un desplegament progressiu (Rolling Update) sense talls de servei:
`terraform apply -auto-approve -lock=false`

**Com escalar un servei:**
Per augmentar la capacitat del frontend o del backend davant un pic de trànsit, s'ha de modificar el paràmetre `replicas` dins del recurs corresponent al fitxer `main.tf` de Terraform (per exemple, canviar `replicas = 1` a `replicas = 3`) i tornar a executar `terraform apply`.
Alternativament, es pot fer de manera directa per consola mitjançant l'ordre:
`kubectl scale deployment nginx --replicas=3`

**Com comprovar els logs dels serveis:**
1. Obtenir el nom exacte del Pod actiu: `kubectl get pods`
2. Consultar les traces o logs de l'aplicació en temps real: `kubectl logs <nom_del_pod>`
3. Si volem veure els logs en directe (com un `tail -f`), afegim l'argument `-f`: `kubectl logs -f <nom_del_pod>`

**Com accedir al dashboard d'observabilitat:**
Minikube inclou un tauler de control gràfic natiu que es pot aixecar des de la terminal per monitorar el rendiment, l'ús de memòria i l'estat de salut de la infraestructura de GreenDevCorp. S'activa executant:
`minikube dashboard`

### 4. Guia de Resolució de Problemes (Troubleshooting Guide)
**Cas Pràctic 1: Un servei dona l'error CrashLoopBackOff o Error constantment. Com el diagnostico?**
- **Pas 1:** Revisar l'estat amb `kubectl get pods` per identificar quin servei està fallant.

- **Pas 2:** Executar `kubectl logs <nom_del_pod>`. Si el log mostra el missatge `exec format error`, significa que s'ha descarregat de Docker Hub una imatge compilada per a una arquitectura de processador incorrecta (com ara AMD64 en una màquina virtual ARM64 de UTM).

- **Solució:** S'ha de forçar la compilació local mitjançant `minikube image build`, i comprovar que al fitxer `main.tf` de Terraform s'ha establert de manera estricta el paràmetre `image_pull_policy = Never` per bloquejar les descàrregues d'Internet.

**Cas Pràctic 2: El servei Nginx no pot comunicar-se amb el backend. Com faig el depurament?**
- **Pas 1:** Validar que el servei backend existeix i té una IP interna assignada executant kubectl get svc.

- **Pas 2:** Comprovar que els ports coincideixen. El ConfigMap ha de tenir fixat el port 3000 per al backend i el port 80 per a l'Nginx.

- **Pas 3:** Validar que no hi hagi cap Network Policy restrictiva que estigui tallant el trànsit de forma accidental entre el segment web i l'aplicació. Es pot provar la connexió executant un curl des de dins del propi pod:
`kubectl exec -it <nom_pod_nginx> -- curl http://backend:3000`

### 5. Guia d'inici ràpid

**Quick Start: Com posar el sistema en marxa?**
Per aixecar la infraestructura completa des de zero en un entorn local, segueix aquests passos exactes a la terminal:

1. **Clonar el repositori i preparar l'entorn:**
   ```bash
   git clone <url-del-vostre-repositori>
   cd gsx-practica2
   minikube start
   ```

2. **Compilar les imatges localment (per evitar problemes d'arquitectura):**
   ```bash
   cd docker-compose
   minikube image build -t oscarlopezgsx/nginx-gsx:v1 -f Dockerfile
   minikube image build -t oscarlopezgsx/app-simple:v1 -f Dockerfile.app
   ```

3. **Desplegar la infraestructura amb Terraform:**
   ```bash
   cd ../terraform
   terraform init
   terraform apply -auto-approve -lock=false
   ```

4. **Verificar el desplegament:**
   ```bash
   kubectl get pods
   minikube service nginx --url
   ```

### Links a altres documentacions
**Enllaços a la resta de documentació:**
* [Repte B: Full Integration Test](README_challengeB.md)
* [Repte D: Reflexions](README_challengeD.md)
