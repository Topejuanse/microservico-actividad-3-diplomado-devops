# Entorno local con k3d + Argo CD

Levanta un clúster Kubernetes local en Docker (k3d) con **Argo CD** y los dos
microservicios del repo (`servicio-usuarios` y `servicio-pedidos`) desplegados
por GitOps desde sus charts de Helm.

## Arquitectura

```
                       k3d (1 server + 2 agents en Docker)
  ┌───────────────────────────────────────────────────────────────┐
  │  Traefik (Ingress)  ──▶ :80/:443  ──▶ mapeado a host :8080/:8443│
  │                                                               │
  │  ns argocd:            Argo CD (server, repo-server,           │
  │                        application-controller, redis)          │
  │                          │  sincroniza desde GitHub (main)     │
  │                          ▼                                     │
  │  ns microservicios:   servicio-usuarios-chart  (Deploy + Svc)  │
  │                       servicio-pedidos-chart   (Deploy + Svc)  │
  └───────────────────────────────────────────────────────────────┘
```

- **Imágenes**: se usan las publicadas en Docker Hub por el pipeline de Jenkins
  (`jfuquene/servicio-usuarios` y `servicio-pedidos`), con el tag
  que esté fijado en cada `helm-charts/*/values.yaml`. No se construye nada en local.
- **Fuente de Argo CD**: el repo de GitHub
  `Topejuanse/microservico-actividad-3-diplomado-devops`, rama `main`, carpetas
  `helm-charts/servicio-usuarios-chart` y `helm-charts/servicio-pedidos-chart`.
  Argo CD sincroniza automáticamente lo que Jenkins commitea a `main`.

## Requisitos

| Herramienta | Instalación en macOS |
|-------------|----------------------|
| Docker (Desktop / Colima / Rancher Desktop) | ya en uso en el equipo |
| [k3d](https://k3d.io) | `brew install k3d` |
| kubectl | `brew install kubectl` |
| Helm | `brew install helm` |

## Uso rápido

```bash
# desde la raíz del repo
make -C k3d up        # crea el clúster, instala Argo CD y despliega los 2 servicios
make -C k3d status    # estado de nodos, pods, Applications e Ingress
make -C k3d down      # elimina el clúster por completo
```

Equivalente sin `make`:

```bash
bash k3d/scripts/up.sh
bash k3d/scripts/status.sh
bash k3d/scripts/down.sh
```

La primera ejecución tarda **3-5 min** (descarga de imágenes de k3s y Argo CD).

## Accesos

`*.localtest.me` resuelve a `127.0.0.1`, así que no hay que editar `/etc/hosts`.

| Qué | URL |
|-----|-----|
| Argo CD UI | http://argocd.localtest.me:8080 — usuario `admin` |
| servicio-usuarios | http://usuarios.localtest.me:8080/db_usuarios/1 |
| servicio-pedidos | http://pedidos.localtest.me:8080/pedidos |

Password de `admin` de Argo CD:

```bash
make -C k3d password
```

Alternativa a la UI por Ingress (útil si el puerto 8080 está ocupado):

```bash
make -C k3d ui        # port-forward -> http://localhost:8081
```

## Archivos

| Ruta | Función |
|------|---------|
| `k3d-config.yaml` | Definición del clúster k3d (1 server, 2 agents, puertos 8080/8443) |
| `argocd/values.yaml` | Valores de Helm para Argo CD (modo HTTP para Ingress, footprint reducido) |
| `argocd/apps/*.yaml` | Una `Application` de Argo CD por microservicio |
| `argocd/root-app.yaml` | App-of-Apps opcional (ver más abajo) |
| `manifests/ingress.yaml` | Ingress de Traefik para Argo CD y los dos servicios |
| `scripts/` | `up.sh` / `down.sh` / `status.sh` |
| `Makefile` | Atajos: `up`, `down`, `restart`, `status`, `password`, `ui` |

## App-of-Apps (opcional)

`scripts/up.sh` aplica las `Application` de `argocd/apps/` directamente con
`kubectl`, para que funcione aunque esta carpeta `k3d/` todavía no esté en `main`.

Una vez que `k3d/argocd/apps/` esté commiteado en `main`, puedes pasar al patrón
App-of-Apps puro:

```bash
kubectl apply -f k3d/argocd/root-app.yaml
```

`root-app` leerá las Application hijas desde el repo y las mantendrá sincronizadas.

## Notas

- Los charts referencian `.Values.image.imagePullPolicy` y `.Values.service.targetPort`,
  mientras que `values.yaml` define `pullPolicy` y `targertPort`. Al renderizar
  quedan vacíos y Kubernetes aplica sus valores por defecto (`IfNotPresent` y
  `targetPort == port`), por lo que **el despliegue funciona igual**; es solo
  ruido cosmético en los charts.
- Para probar un tag de imagen distinto sin pasar por Jenkins: edita el `tag`
  en `helm-charts/<chart>/values.yaml`, haz commit/push a `main` y Argo CD
  sincroniza solo (o pulsa *Sync* en la UI / `kubectl -n argocd annotate app <name> argocd.argoproj.io/refresh=hard --overwrite`).
- Para forzar una resincronización inmediata de todo:
  `kubectl -n argocd patch app servicio-usuarios --type merge -p '{"operation":{"sync":{}}}'`.
