# Challenge B: Full Integration Test

## Documentació del procés

## 1. Quant ha trigat el desplegament?
El desplegament automàtic final de la infraestructura utilitzant Terraform ha trigat exactament 1.812 segons per orquestrar i sincronitzar l'estat desitjat amb el clúster de Kubernetes (segons el registre de l'ordre time de Linux). Un cop Terraform ha completat la seva execució, els contenidors han assolit l'estat operatiu intern de forma correcte (estat Running) en 24 segons.

## 2. Troubleshooting

### Conflicte d'arquitectures a macOS i descàrrega d'imatges
Causa: Al executar tota la infraestructura des d'un Mac amb Apple Silicon (ARM64), Kubernetes intentava descarregar de Docker Hub les imatges compilades originalment per a Intel/Windows (AMD64), i provocava un error de compatibilitat i es col·lapsaven els pods.
Solució: Vam fer l'entorn flexible i compatible per a qualsevol arquitectura integrant un sistema de construcció local. Vam eliminar els desplegaments antics amb la comanda `kubectl delete deployment backend nginx`, vam compilar les noves imatges amb `minikube image build` i vam afegir `image_pull_policy = "Never"` al fitxer `main.tf`. Això força el clúster a utilitzar sempre les imatges natives generades per la màquina que executa el codi. 

## 3. Captures dels components.
Això es podia llegir a les nostres terminals al final del procès:

```text
oscar@debian-gsx:~/gsx-practica2/terraform$ kubectl get pods
NAME                      READY   STATUS    RESTARTS   AGE
backend-95dfb4f87-mkxbx   1/1     Running   0          24s
nginx-7b77fbc9b5-hsr4f    1/1     Running   0          24s
```

```text
Apply complete! Resources: 2 added, 0 changed, 0 destroyed.

Outputs:

missatge_exit = "La infraestructura d'Nginx i Backend s'ha creat correctament amb Terraform!"

real	0m1.812s
user	0m0.322s
sys	0m0.037s
```
