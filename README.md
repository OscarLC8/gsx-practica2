#Documentació Setmana 12: Disseny de xarxa i identitat
En aquesta documentació s'explica el disseny de l'arquitectura de xarxa per a GreenDevCorp , la implementació de seguretat mitjançant polítiques de Kubernetes i la recerca sobre serveis core i gestió d'identitats.

##1. Disseny de l'arquitectura de xarxa
En aquesta setmana, es vol proporcionar una arquitectura segura i segmentada per a diferents entorns i usuaris.

###1.1 Pla d'adreçament IP (CIDR)
S'han definit els següents segments de xarxa per a tota la organització utilitzant el rang global 10.0.0.0/16. Aquest rang s'ha dividit en les següents subxaxes:
- Desenvolupament: 10.0.1.0/24. Aquesta subxarxa admet fins a 254 IPs i conté els pods i serveis d'entorn de proves on els desenvolupadors treballen diàriament.
- Staging: 10.0.2.0/24. Entorn pre-producció per validar les noves versions abans del llançament oficial.
- Producció: 10.0.3.0/24. Entorn altament aïllat on s'executen les aplicacions finals de cara a l'usuari i la base de dades.
- Partners Externs: 10.0.10.0/24. Zona aïllada per atorgar accessos temporals a contractistes i col·laboradors externs, garantint que no interactuïn de forma directa amb les zones més sensibles de l'empresa.

Justificació: Com quue en GreenDevCorp hi han més de 20 persones i es preveu un ràpid creixement, assignar blocs de 254 adreces per a cada entorn permet un creixement ordenat de l'arquitectura sense esgotar ràpidament les direccions IP i també facilita l'escriptura de regles de tallafocs senzilles i clares.

###1. Diagrama arquitectura de xarxa
A continuació es mostra el diagrama de l'arquitectura de la xarxa, amb els seus segments i connexions corresponents:

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

##2. Implementació seguretat i límits

Per a evitar accessos indeguts i altres problemes de seguretat, s'han implkementat diferents mesures de seguretat.

###2.1 Actualització de l'entorn
Les NetworkPolicies requereixen un pluguin de xarxa específic, el CNI. Per a poder treballar més còmodament, s'han aplicat els canvis següents:
1. Ampliació de recursos de la màquina virtual a 2 CPUs i 4GB de RAM
2. Desplegament de Minikube activant el motor de xarxa Cilium amb la comanda:
`minikube start --cni=cilium --memory=4096`

###2.2 Polítiques aplicades i límits de seguretat
S'han aplicat les següents funcionalitats per a regular el trànsit:

`deny-all.yaml`: Implementa una política d'aïllament per defecte. Aquest arxiu bloqueja tot el trànsit entrant i sortint a l'espai de treball.
`allow-backend-to-db.yaml`: Afegeix una regla d'entrada (Ingress). Exclusivament els pods amb etiquetes `app: backend` i `env: production` poden connectar-se al pod de la base de dades pel port 5432.
`allow-egress-rules.yaml`: Afegeix regles de sortida (Egress). Permet resoldre noms DNS (port 53)  i autoritza expressament al backend de producció a enviar dades cap a la base de dades.

###2.3 Proves de funcionament
S'han desplegat 3 pods simulats per a validar la implementació
