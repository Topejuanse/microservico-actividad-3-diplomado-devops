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

        stage('2. Build Docker Images') {
            steps {
                script {

                    echo "Construyendo imagen para servicio-usuarios..."
                    sh "docker build -t servicio-usuarios:${IMAGE_TAG} ./servicio-usuarios"

                    echo "Construyendo imagen para servicio-pedidos..."
                        sh "docker build -t servicio-pedidos:${IMAGE_TAG} ./servicio-pedidos"
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
                    sh '''
                        git config user.email "jenkins@bot.local"
                        git config user.name "Jenkins Pipeline"
                        git add helm-charts/
                        git diff-index --quiet HEAD || git commit -m "Tarea: Actualizar image tag to ${IMAGE_TAG} [skip ci]"
                        git push origin HEAD:main
                    '''
                }
            }
        }
    }
}
