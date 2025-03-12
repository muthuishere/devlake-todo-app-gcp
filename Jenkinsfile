pipeline {
    agent any
    tools {
        jdk 'JDK21'
        nodejs 'nodejs23'
 gcloud 'gcpsdk'  // Changed from 'google-cloud-sdk' to 'gcloud'
    }
    environment {
        PROJECT_ID = 'devlakedemo'
        APP_NAME = 'todo-app-gcp'
        REGION = 'us-central1'
        DOCKER_IMAGE = "gcr.io/${PROJECT_ID}/${APP_NAME}"
        CREDENTIALS_ID = 'gcp-credentials'
        // Define cache paths
        GRADLE_USER_HOME = "${WORKSPACE}/.gradle"
        DOCKER_BUILDKIT = '1' // Enable BuildKit for better Docker build performance

    }

    options {
        // Add timestamps to console output
        timestamps()
        // Preserve stashes and caches for fast rebuilds
        preserveStashes()
    }

    stages {
       stage('Setup Google Cloud SDK') {
            steps {
                // Authenticate with Google Cloud
                withCredentials([file(credentialsId: env.CREDENTIALS_ID, variable: 'GC_KEY')]) {
                    sh '''
                        gcloud auth activate-service-account --key-file=$GC_KEY
                        gcloud config set project ${PROJECT_ID}
                        gcloud auth configure-docker
                    '''
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
                    // Setup JDK 21
                    def javaHome = tool name: 'JDK21'
                    env.JAVA_HOME = javaHome
                    env.PATH = "${javaHome}/bin:${env.PATH}"

                    // Create cache directories if they don't exist
                    sh """
                        mkdir -p ${GRADLE_USER_HOME}
                        mkdir -p ~/.docker
                    """
                }
            }
        }

        stage('Build Application') {
            steps {
                // Cache Gradle dependencies and build cache
                cache(maxCacheSize: 250, caches: [
                    arbitraryFileCache(path: "${GRADLE_USER_HOME}/caches"),
                    arbitraryFileCache(path: "${GRADLE_USER_HOME}/wrapper")
                ]) {
                    sh '''
                        ./gradlew clean build -x test \
                            --no-daemon \
                            --build-cache \
                            --gradle-user-home="${GRADLE_USER_HOME}"
                    '''
                }
            }
        }

        stage('Build and Push Docker Image') {
            steps {
                script {
                    def imageTag = "v${BUILD_NUMBER}"

                    // Configure Docker with GCP credentials
                    sh "gcloud auth configure-docker"

                    // Build and push Docker image
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


            // Clean workspace while preserving cache
 cleanWs(patterns: [
                [pattern: '**/build/**', type: 'INCLUDE'],
                [pattern: '**/target/**', type: 'INCLUDE'],
                [pattern: '.gradle/**', type: 'EXCLUDE'],
                [pattern: '.docker/**', type: 'EXCLUDE'],

            ])
        }
    }
}
