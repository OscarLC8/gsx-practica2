# Documentació Setmana 12: Disseny de xarxa i identitat
En aquesta documentació s'explica el disseny de l'arquitectura de xarxa per a GreenDevCorp , la implementació de seguretat mitjançant polítiques de Kubernetes i la recerca sobre serveis core i gestió d'identitats.

## 1. Disseny de l'arquitectura de xarxa
En aquesta setmana, es vol proporcionar una arquitectura segura i segmentada per a diferents entorns i usuaris.

### 1.1 Pla d'adreçament IP (CIDR)
S'han definit els següents segments de xarxa per a tota la organització utilitzant el rang global 10.0.0.0/16. Aquest rang s'ha dividit en les següents subxaxes:
- **Desenvolupament**: 10.0.1.0/24. Aquesta subxarxa admet fins a 254 IPs i conté els pods i serveis d'entorn de proves on els desenvolupadors treballen diàriament.
- **Staging**: 10.0.2.0/24. Entorn pre-producció per validar les noves versions abans del llançament oficial.
- **Producció**: 10.0.3.0/24. Entorn altament aïllat on s'executen les aplicacions finals de cara a l'usuari i la base de dades.
- **Partners Externs**: 10.0.10.0/24. Zona aïllada per atorgar accessos temporals a contractistes i col·laboradors externs, garantint que no interactuïn de forma directa amb les zones més sensibles de l'empresa.

Justificació: Com quue en GreenDevCorp hi han més de 20 persones i es preveu un ràpid creixement, assignar blocs de 254 adreces per a cada entorn permet un creixement ordenat de l'arquitectura sense esgotar ràpidament les direccions IP i també facilita l'escriptura de regles de tallafocs senzilles i clares.

### 1. Diagrama arquitectura de xarxa
A continuació es mostra el diagrama de l'arquitectura de la xarxa, amb els seus segments i connexions corresponents:
```text
[ INTERNET / PARTNERS EXTERNS ]
           |
           v
+-----------------------------+
|    LOAD BALANCER / DMZ      | (10.0.10.0/24)
+-----------------------------+
           |
           v
    [ FIREWALL INTERN ]
           |
   +-------+-------+
   |               |
   v               v
[ DEV ]       [ STAGING ]
10.0.1.0/24   10.0.2.0/24
   |               |
   x (Blocked)     x (Blocked)
   |               |
   +---------------+
           |
           v
     [ PRODUCCIÓ ]
     10.0.3.0/24
      /         \
 [Backend] --> [Base de Dades]
```
## 2. Implementació seguretat i límits

Per a evitar accessos indeguts i altres problemes de seguretat, s'han implkementat diferents mesures de seguretat.

### 2.1 Actualització de l'entorn
Les NetworkPolicies requereixen un pluguin de xarxa específic, el CNI. Per a poder treballar més còmodament, s'han aplicat els canvis següents:
1. Ampliació de recursos de la màquina virtual a 2 CPUs i 4GB de RAM
2. Desplegament de Minikube activant el motor de xarxa Cilium amb la comanda:
`minikube start --cni=cilium --memory=4096`

### 2.2 Polítiques aplicades i límits de seguretat
S'han aplicat les següents funcionalitats per a regular el trànsit:

`deny-all.yaml`: Implementa una política d'aïllament per defecte. Aquest arxiu bloqueja tot el trànsit entrant i sortint a l'espai de treball.
`allow-backend-to-db.yaml`: Afegeix una regla d'entrada (Ingress). Exclusivament els pods amb etiquetes `app: backend` i `env: production` poden connectar-se al pod de la base de dades pel port 5432.
`allow-egress-rules.yaml`: Afegeix regles de sortida (Egress). Permet resoldre noms DNS (port 53)  i autoritza expressament al backend de producció a enviar dades cap a la base de dades.

### 2.3 Proves de funcionament
S'han desplegat 3 pods simulats per a validar la implementació
- Pod DB: `app=db, env=production` (Servidor al port 5432).

- Pod Backend-Prod: `app=backend, env=production.`

- Pod Backend-Dev: `app=backend, env=development`.

Validacions: s'ha utilitzat la comanda `curl`. S'ha pogut observar un bloqueig efectiu d'intent de connexió a la base de dades des del pod Backend-Dev, que ha resultat en Timeout. Per altra banda, l'intent de connexió des del pod Backend-Prod és acceptat de forma correcta pel servidor i es rep una resposta.

## 3. Recerca dels serveis de xarxa
La nostra arquitectura depèn de 3 serveis fonamentals per a funcionar correctament:

### 3.1 DNS (Domain Name System)
El DNS actua com el "directori telefònic" d'Internet. Tradueix noms fàcils de llegir i recordar (com api.greendevcorp.com) en adreces IP numèriques que els sistemes informàtics fan servir per localitzar-se (com 10.0.3.45).  Una organització necessita un DNS intern perquè permet a les aplicacions comunicar-se referenciant el servei en lloc d'una IP estàtica. Si un servidor es canvia de màquina (i la seva IP canvia), gràcies al DNS cap dels altres sistemes o empleats notarà la interrupció, ja que el nom de domini es manté igual.

### 3.2 DHCP (Dynamic host Configuration Protocol)
El DHCP és un servei encarregat de distribuir adreces IP i paràmetres de xarxa automàticament a qualsevol ordinador o dispositiu que es connecta a l'organització.  S'utilitza per evitar el caos i reduir feina d'administració. Si no existís, un tècnic hauria de configurar a màcada mòbil i cada portàtil nou o d'un soci extern amb la subxarxa assignada. El DHCP assigna les dades de configuració i recupera les IPs de dispositius desconnectats per reciclar-les.

### 3.3 NTP (Network Time Protocol)
Aquest protocol sincronitza els rellotges de tots els servidors, ordinadors i contenidors per tenir l'hora exacta en fracció de segons.  
Mantenir els sistemes sincronitzats és crucial tant per a la funcionalitat tècnica (els certificats SSL es poden invalidar si el rellotge de l'equip client té l'hora endarrerida) com de seguretat. En cas d'incident, si els logs dels sistemes A i B tenen minuts de diferència, és completament impossible rastrejar com es va originar o escampar l'atac (clau per la justificació de dades / compliance).

---

## 4. Recerca: Gestió d'identitats

### 4.1 Autenticació vs Autorització
Son dos conceptes que solen anar de la mà, pero tenen significats completament diferents:

- **Autenticació**: Consisteix a verificar qui ets. És el moment de presentar l'usuari, la contrasenya o realitzar l'autenticació multifactor per demostrar la identitat (ex: Iniciar sessió).

- **Autorització**: És el procés que avalua què pots fer dins de la plataforma una vegada la teva identitat s'ha verificat. Per exemple, comprovar si un compte té privilegis de visualització, edició o d'administrador.

### 4.2 Identitat centralitzada
Si es gestionen les comptes de forma descentralitzada, es poden causar greus problemes de seguretat.

- **LDAP**: És el protocol principal i "lleuger" utilitzat per cercar, llegir i validar identitats dins d'un directori jeràrquic informàtic unificat.

- **Active Directory** (AD): És el servei creat per Microsoft que usa LDAP juntament amb altres tecnologies. A més de comptes d'usuari, gestiona permisos i polítiques d'ordinadors d'escriptori i impressores d'una empresa de manera granular.

- **SSO** (Single Sign-On): És el sistema que permet a un usuari iniciar sessió només un cop en un portal i, màgicament, obtenir accés directe a Slack, correu, repositoris i núvol sense haver d'escriure la contrasenya de nou a cada aplicació.

L'ús d'identitats centralitzades elimina la problemàtica d'un extreballador mantenint l'accés a dades perquè ningú va recordar eliminar el seu compte del servidor X. Les petites empreses necessiten una base centralitzada per ser àgils i no sobrecarregar tècnics resetejant contrasenyes de serveis inconnexos, mentre que per les grans empreses és absolutament indispensable per garantir la seguretat i auditoria completa a gran escala.

### 4.3 Estratègia d'identitat per GreenDevCorp
Degut a que l'empresa ja té més de 20 persones dividides en diferents equips i col·laboradors externs, es recomana implementar un sistema d'Identitat al Núvol basat en SSO (com per exemple Google Workspace, Okta o Entra ID/Azure AD).

- Per què? La càrrega de mantenir un servidor propi OpenLDAP o AD físic intern  exigiria dedicació constant d'un equip tècnic per aplicació de pegats i seguretat. Una eina SaaS externa suporta natius moderns com GitHub i les eines CI/CD utilitzades per GreenDevCorp.

- Trade-offs (compromisos): Com a punt negatiu es passa a dependre dels servidors i preus d'una empresa de tercers (cost per usuari mensual en lloc de cost lliure/opensource). Tot i això, guanyem integració directa

---

## 5. Anàlisi de seguretat i mitigació.
S'ha de tenir en compte que sempre hi poden haver problemes i forats de seguretat. S'ha de ser capaç d'identificar aquests riscos i saber com combatre'ls. Per exemple:

1. Risc: Error humà obrint la xarxa
En aplicar una NetworkPolicy incorrecta amb massa permissivitat (exemple: creació d'un selector que deixi la base de dades visible a la xarxa de Partners Externs).
- Mitigació: Tractar les configuracions de seguretat mitjançant IaC (Infrastructure as Code) , aplicant validacions automatitzades de l'acció mitjançant CI Pipeline abans de realitzar canvis al clúster i incloure obligatòriament la política general de bloqueig (Deny All) sempre actiu

2. Risc: Usuari extern compromès
Un Partner pot fer clic a un enllaç fraudulent i veure les seves credencials compromeses, atorgant a l'atacant entrada directa a la seva subxarxa VPN (10.0.10.0/24).
- Mitigació: Forçar Autenticació Multifactor (MFA/2FA) a nivell d'SSO. Tot i així, en cas de robatori de sessió vàlida, l'existència de NetworkPolicies i segmentació per subxarxes limitarà el moviment lateral (l'atacant podrà entrar però es toparà immediatament amb murs interns que l'aturaran des d'accedir al Codi Font o la Producció). 
