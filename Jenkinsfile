pipeline {
    agent any

    environment {
        PROJECT_ID = 'devlakedemo'
        APP_NAME = 'todo-app-gcp'
        REGION = 'us-central1'  // or your preferred region
        DOCKER_IMAGE = "gcr.io/${PROJECT_ID}/${APP_NAME}"
        CREDENTIALS_ID = 'gcp-credentials'  // ID of your GCP credentials in Jenkins
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build Application') {
            steps {
                sh './gradlew clean build -x test'
            }
        }

        stage('Build and Push Docker Image') {
            steps {
                script {
                    // Authenticate with GCP
                    withCredentials([file(credentialsId: env.CREDENTIALS_ID, variable: 'GC_KEY')]) {
                        sh "gcloud auth activate-service-account --key-file=${GC_KEY}"
                        sh "gcloud auth configure-docker"

                        // Build the Docker image
                        def imageTag = "v${BUILD_NUMBER}"
                        sh "docker build -t ${DOCKER_IMAGE}:${imageTag} ."
                        sh "docker push ${DOCKER_IMAGE}:${imageTag}"

                        // Tag as latest
                        sh "docker tag ${DOCKER_IMAGE}:${imageTag} ${DOCKER_IMAGE}:latest"
                        sh "docker push ${DOCKER_IMAGE}:latest"
                    }
                }
            }
        }

        stage('Deploy to Cloud Run') {
            steps {
                script {
                    withCredentials([file(credentialsId: env.CREDENTIALS_ID, variable: 'GC_KEY')]) {
                        sh """
                            gcloud auth activate-service-account --key-file=${GC_KEY}
                            gcloud run deploy ${APP_NAME} \
                                --image ${DOCKER_IMAGE}:latest \
                                --platform managed \
                                --region ${REGION} \
                                --project ${PROJECT_ID} \
                                --allow-unauthenticated
                        """
                    }
                }
            }
        }
    }

    post {
        always {
            // Clean up
            sh 'gcloud auth revoke --all'
        }
    }
}
