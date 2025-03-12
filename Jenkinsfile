pipeline {
    agent any
    tools {
        jdk 'JDK21'
        nodejs 'nodejs23'
    }
    environment {
        PROJECT_ID = 'devlakedemo'
        APP_NAME = 'todo-app-gcp'
        REGION = 'us-central1'
        DOCKER_IMAGE = "gcr.io/${PROJECT_ID}/${APP_NAME}"
        CREDENTIALS_ID = 'app-gcp-credentials'
        GRADLE_USER_HOME = "${WORKSPACE}/.gradle"
        DOCKER_BUILDKIT = '1'
    }

    options {
        timestamps()
    }

    stages {
        stage('Setup Google Cloud SDK') {
            steps {
                sh 'which gcloud'
                sh 'echo $PATH'

                withCredentials([file(credentialsId: env.CREDENTIALS_ID, variable: 'GC_KEY')]) {
                    sh """
                        set -xe
                        ls -l \$GC_KEY
                        gcloud auth activate-service-account --key-file=\$GC_KEY || exit 1
                        gcloud config set project ${PROJECT_ID} || exit 1
                        gcloud auth configure-docker || exit 1
                        gcloud config list
                    """
                }
            }
        }

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Setup JDK and Cache') {
            steps {
                script {
                    def javaHome = tool name: 'JDK21'
                    env.JAVA_HOME = javaHome
                    env.PATH = "${javaHome}/bin:${env.PATH}"

                    sh """
                        mkdir -p ${GRADLE_USER_HOME}
                        mkdir -p ~/.docker
                    """
                }
            }
        }

        stage('Build Application') {
            steps {
                sh """
                    ./gradlew clean build -x test \
                        --no-daemon \
                        --build-cache \
                        --gradle-user-home="${GRADLE_USER_HOME}"
                """
            }
        }

        stage('Build and Push Docker Image') {
            steps {
                script {
                    def imageTag = "v${BUILD_NUMBER}"

                    sh "gcloud auth configure-docker"

                    sh """
                        DOCKER_BUILDKIT=1 docker build \
                            --cache-from ${DOCKER_IMAGE}:latest \
                            --build-arg BUILDKIT_INLINE_CACHE=1 \
                            -t ${DOCKER_IMAGE}:${imageTag} \
                            -t ${DOCKER_IMAGE}:latest \
                            .
                    """

                    sh """
                        docker push ${DOCKER_IMAGE}:${imageTag}
                        docker push ${DOCKER_IMAGE}:latest
                    """
                }
            }
        }

        stage('Deploy to Cloud Run') {
            steps {
                sh """
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

    post {
        always {
            cleanWs(patterns: [
                [pattern: '**/build/**', type: 'INCLUDE'],
                [pattern: '**/target/**', type: 'INCLUDE'],
                [pattern: '.gradle/**', type: 'EXCLUDE'],
                [pattern: '.docker/**', type: 'EXCLUDE']
            ])
        }
    }
}
