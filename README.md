# gsx-practica2

# Documentació Setmana 11: Infraestructura com a Codi (IaC) i CI/CD

## 1. Elecció de l'eina IaC: Terraform vs. Ansible
Per a la implementació d'aquesta setmana, hem optat per *Terraform*. Les raons principals per triar aquesta eina en lloc d'Ansible són:

### Model Declaratiu:
Terraform ens permet definir l'estat final desitjat de la infraestructura. L'eina s'encarrega de calcular les diferències entre l'estat actual i el desitjat, simplificant la gestió de recursos complexos a Kubernetes.

### Gestió d'Estat (State):
Mitjançant el fitxer `.tfstate`, Terraform manté un control estricte del que s'ha desplegat, garantint la *idempotència* (podem executar el codi moltes vegades i el resultat serà sempre el mateix sense duplicar recursos).

### Especialització:
Mentre que Ansible és ideal per a la configuració interna de sistemes operatius, Terraform és l'estàndard per a l'aprovisionament de recursos de xarxa i orquestració.

--- 

## 2. Descripció de la Pipeline CI/CD
Hem dissenyat un flux de treball que automatitza les tasques repetitives i garanteix la qualitat del codi.

### Flux d'Integració Contínua (CI) a GitHub Actions:
Quan es realitza un `push` a la branca de treball o un `merge` a `main`, s'activa el fitxer `.github/workflows/ci.yml`:

*1 -> Validació de la IaC:* S'executen les ordres `terraform fmt` i `terraform validate` per assegurar que el codi no tingui errors de sintaxi o format.
*2 -> Construcció d'Imatges:* Es generen les imatges de Docker per al Backend i per a Nginx.
*3 -> Publicació al Registry:* Les imatges es pugen automàticament a Docker Hub utilitzant secrets de GitHub per protegir les credencials.

### Flux de Desplegament Continu (CD) Local:
Com que els servidors de GitHub no tenen accés al nostre clúster de *Minikube* local, el desplegament final s'executa des de la nostra màquina:

- Es descarreguen les imatges ja validades de Docker Hub i s'apliquen els canvis a Minikube mitjançant Terraform.

--- 

## 3. Gestió de l'etiqueta de la imatge (Image Tag)
Per mantenir la traçabilitat total del sistema, seguim aquesta estratègia:

### Identificador únic:
Utilitzem el *Commit SHA* de Git com a etiqueta de la imatge (ex: `v-745397f`) en lloc d'etiquetes genèriques com `latest`.

### Configuració en el codi:
Aquesta etiqueta es defineix com una variable al fitxer `variables.tf` i s'injecta en el recurs del contenidor al `main.tf`. Això permet actualitzar la versió de l'aplicació a Kubernetes sense canviar la lògica del desplegament.

--- 


## 4. Organització del Codi Terraform
Hem seguit les millors pràctiques d'organització per evitar fitxers massa llargs i fer el codi reutilitzable:

*Fitxer* --> *Funció*
`main.tf`      --> Defineix els recursos de Kubernetes (Deployments, Services, ConfigMaps).
`variables.tf` --> Conté els paràmetres configurables (noms d'usuari, tags d'imatges) per evitar el hardcoding.
`outputs.tf`   --> Mostra informació rellevant per pantalla després del desplegament.

--- 

## Guia Operacional (Runbook)
Aquesta secció serveix com a manual per a futurs operadors del sistema.

### Passos per a un desplegament des de zero:
*1. Preparació:* Iniciar el clúster local amb `minikube start`.
*2. Inicialització:* Dins la carpeta `terraform/`, executar terraform `init` per descarregar els proveïdors.
*3. Planificació:* Executar `terraform plan` per revisar quins canvis es faran al clúster.
*4. Aplicació:* Executar `terraform apply` per desplegar tota la infraestructura automàticament.

### Verificació del sistema:
- Comprovar que els Pods estiguin en marxa: `kubectl get pods`.
- Verificar que els serveis es comuniquin: `kubectl exec` entre contenidors.
- Confirmar que la pipeline de GitHub estigui en verd (checkmarks passats).
