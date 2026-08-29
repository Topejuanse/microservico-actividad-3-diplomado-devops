# Jenkins local con Docker Compose

Jenkins LTS aprovisionado por **Configuration as Code (JCasC)**, con un sidecar
`docker:dind` para que los pipelines hagan `docker build` / `docker push` sin
tocar el daemon del host. Al arrancar queda listo con el admin, las credenciales
y el job `microservicios-pipeline` ya creados.

## Contenido

| Archivo | Función |
|---|---|
| `docker-compose.yml` | Servicios `jenkins` + `docker` (dind), volúmenes y red |
| `Dockerfile` | Imagen de Jenkins + Docker CLI/buildx + plugins + JCasC, sin wizard |
| `plugins.txt` | Lista de plugins (JCasC, job-dsl, pipeline, git, docker-workflow, …) |
| `casc/jenkins.yaml` | Config declarativa: seguridad, admin, credenciales y el job del pipeline |
| `.env.example` | Plantilla de variables (admin, tokens, repo). Cópiala a `.env` |
| `.gitignore` | Ignora `.env` |

## Requisitos

- Docker con Compose v2 (`docker compose`).

## Puesta en marcha

```bash
cd jenkins
cp .env.example .env          # y edita: admin, DOCKERHUB_*, GITHUB_*
docker compose up -d --build  # 1er build ~2-4 min (descarga de plugins)
```

- UI: http://localhost:8080 (o el `JENKINS_HTTP_PORT` que pongas en `.env`)
- Login: `JENKINS_ADMIN_ID` / `JENKINS_ADMIN_PASSWORD` del `.env` (sin `.env` arranca con `admin` / `admin`)
- Ver arranque: `docker compose logs -f jenkins`

## Qué queda configurado

- **Credenciales** (globales, tipo usuario/contraseña):
  - `dockerhub-team-credentials` ← `DOCKERHUB_USERNAME` / `DOCKERHUB_TOKEN`
  - `github-credentials` ← `GITHUB_USERNAME` / `GITHUB_TOKEN`

  Son los mismos IDs que referencia el [Jenkinsfile](../Jenkinsfile), así que el
  pipeline funciona sin tocar nada más.
- **Job** `microservicios-pipeline`: pipeline que lee el `Jenkinsfile` de
  `GIT_REPO_URL` (rama `GIT_BRANCH`). Ejecútalo con **Build Now** o deja que el
  **polling SCM cada 1 min** (`scm('* * * * *')`) lo dispare ante cambios en `main`
  fuera de `helm-charts/`.

## Operación

```bash
docker compose ps                 # estado
docker compose logs -f jenkins    # logs
docker compose restart jenkins    # recargar tras cambiar casc/jenkins.yaml + rebuild
docker compose down               # parar (conserva datos en el volumen)
docker compose down -v            # parar y BORRAR jenkins-data (empezar de cero)
```

Tras editar `plugins.txt`, `Dockerfile` o `casc/jenkins.yaml`:

```bash
docker compose up -d --build
```

(los cambios de JCasC también se aplican desde *Manage Jenkins → Configuration as
Code → Reload existing configuration*).

## Notas

- **Puerto 8080**: colisiona con el mapeo del clúster k3d de este repo
  (`k3d/k3d-config.yaml`). Para correr ambos a la vez, cambia `JENKINS_HTTP_PORT`
  en `.env`.
- Sin `DOCKERHUB_*` / `GITHUB_*` válidos en `.env`, las credenciales se crean
  vacías y las etapas de push del pipeline fallarán (login y `git push`).
- `docker:dind` requiere `privileged: true`; los builds quedan aislados en el
  volumen `jenkins-docker-certs` + el daemon del sidecar, no en el host.
- `plugins.txt` no fija versiones: el primer build baja las últimas compatibles
  con esa LTS (requiere internet). Para reproducibilidad, fija `FROM` a un digest
  y añade `:<versión>` a cada plugin.
- `useScriptSecurity: false` en el bloque `security` permite que JCasC cree el job
  vía Job DSL sin aprobación manual de script. Si prefieres el sandbox de Job DSL,
  quítalo y aprueba el script desde *Manage Jenkins → In-process Script Approval*.
- **Zona horaria**: `TZ=America/Bogota` (GMT-5, sin DST) + `-Duser.timezone=America/Bogota`
  en `JAVA_OPTS` (ver `Dockerfile`). Afecta timestamps de builds, el *Git Polling Log*
  y la fecha de los commits que el pipeline hace en la etapa 4.
- **Polling cada 1 min**: Jenkins avisará *"Do you really mean 'every minute'..."* en
  la config del job; es esperado, no un error.
