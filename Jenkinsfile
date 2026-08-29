pipeline {
    agent any

    stages {

        stage('1. Checkout Code') {
            steps {
                script {
                    def scmVars = checkout scm
                    env.GIT_SHA   = scmVars.GIT_COMMIT.take(7)
                    env.IMAGE_TAG = "1.0.${BUILD_NUMBER}-${env.GIT_SHA}"
                    echo "IMAGE_TAG = ${env.IMAGE_TAG}"
                }
            }
        }

        stage('2. Build and push Docker Images') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: 'dockerhub-team-credentials', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                        
                        echo "Iniciando sesión en Docker Hub..."
                        sh 'echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin'

                        echo "Preparando buildx (QEMU + builder multi-arch sobre el daemon dind)..."
                        sh '''
                            docker run --privileged --rm tonistiigi/binfmt --install all
                            docker context inspect dindctx >/dev/null 2>&1 || docker context create dindctx --docker "host=tcp://docker:2376,ca=/certs/client/ca.pem,cert=/certs/client/cert.pem,key=/certs/client/key.pem"
                            docker buildx rm multiarch >/dev/null 2>&1 || true
                            docker buildx create --name multiarch --driver docker-container --use dindctx
                            docker buildx inspect --bootstrap
                        '''

                        echo "Construyendo y subiendo servicio-usuarios (linux/amd64 + linux/arm64)..."
                        sh "docker buildx build --builder multiarch --platform linux/amd64,linux/arm64 -t ${DOCKER_USER}/servicio-usuarios:${IMAGE_TAG} --push ./servicio-usuarios"

                        echo "Construyendo y subiendo servicio-pedidos (linux/amd64 + linux/arm64)..."
                        sh "docker buildx build --builder multiarch --platform linux/amd64,linux/arm64 -t ${DOCKER_USER}/servicio-pedidos:${IMAGE_TAG} --push ./servicio-pedidos"

                    }
                }
            }
        }

        stage('3. Update Helm Chart Values') {
            steps {
                script {
                    echo "Actualizado tags de imagen en Helm values..."
                    sh "sed -i 's/tag: .*/tag: \"${IMAGE_TAG}\"/' helm-charts/servicio-usuarios-chart/values.yaml"
                    sh "sed -i 's/tag: .*/tag: \"${IMAGE_TAG}\"/' helm-charts/servicio-pedidos-chart/values.yaml"
                }
            }
        }

        stage('4. Push Changes to GitHub') {
            steps {
                script{
                    echo "Guardando y subiendo los cambios de los values.yaml..."
                    withCredentials([usernamePassword(credentialsId: 'github-credentials', usernameVariable: 'GIT_USER', passwordVariable: 'GIT_PASS')]) {
                        sh '''
                            git config user.email "jenkins@bot.local"
                            git config user.name "Jenkins Pipeline"
                            git add helm-charts/
                            git diff-index --quiet HEAD || git commit -m "Tarea: Actualizar image tag a ${IMAGE_TAG} [skip ci]"
                            git push https://${GIT_USER}:${GIT_PASS}@github.com/Topejuanse/microservico-actividad-3-diplomado-devops.git HEAD:main
                        '''
                    }
                }
            }
        }
    }
}
