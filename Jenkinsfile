pipeline {
    agent any

    environment {

        IMAGE_TAG = "1.0.${BUILD_NUMBER}"
    }


    stages {

        stage('1. Checkout Code') {
            steps {

                checkout scm
            }
        }

        stage('2. Build and push Docker Images') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                        
                        echo "Iniciando sesión en Docker Hub..."
                        sh 'echo "$DOCKER_PASS | docker login -u "$DOCKER_USER" --password-stdin'

                        echo "Construyendo y subiendo imagen para servicio-usuarios..."
                        sh """
                            docker build -t ${DOCKER_USER}/servicio-usuarios:${IMAGE_TAG} ./servicio-usuarios
                            docker push ${DOCKER_USER}/servicio-usuarios:${IMAGE_TAG}
                        """

                        echo "Construyendo y subiendo imagen para servicio-pedidos..."
                        sh """
                            docker build -t ${DOCKER_USER}/servicio-pedidos:${IMAGE_TAG} ./servicio-pedidos
                            docker push ${DOCKER_USER}/servicio-pedidos:${IMAGE_TAG}
                        """

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
