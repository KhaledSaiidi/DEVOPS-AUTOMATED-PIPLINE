pipeline {
    agent any // This pipeline can run on any available agent

    environment {
        VERSION = "${env.BUILD_ID}" // Set the environment variable VERSION to the build ID
    }

    stages {
        // Stage 1: SonarQube Code Check
        stage("SonarQube Code Check") {
            steps {
                script {
                    // Use SonarQube environment with provided credentials
                    withSonarQubeEnv(credentialsId: 'sonar-token') {
                        sh 'chmod +x gradlew' // Make the Gradle wrapper executable
                        sh './gradlew sonar' // Run SonarQube analysis

                        // Wait for the Quality Gate to pass or fail after a timeout
                        timeout(time: 1, unit: 'HOURS') {
                            def qg = waitForQualityGate()
                            if (qg.status != 'OK') {
                                error "Pipeline aborted due to quality gate failure: ${qg.status}"
                            }
                        }
                    }
                }
            }
        }

        // Stage 2: Docker build/push images
        stage("docker build/push images") {
            steps {
                script {
                    // Use Docker credentials for authentication
                    withCredentials([string(credentialsId: 'docker_pass', variable: 'docker_password')]) {
                        sh '''
                            docker build -t 172.28.200.141:8083/springapp:${VERSION} .
                            docker login -u admin -p $docker_password 172.28.200.141:8083
                            docker push 172.28.200.141:8083/springapp:${VERSION}
                            docker rmi 172.28.200.141:8083/springapp:${VERSION}
                        '''
                    }
                }
            }
        }

        // Stage 3: Identifying mis-configuration with Linting
        stage("identifying mis-configuration with Linting") {
            steps {
                script {
                    dir('kubernetes/') {
                        sh 'microk8s helm lint myapp' // Run Helm linting on the Kubernetes chart
                    }
                }
            }
        }

        // Stage 4: Pushing the Helm charts to Nexus
        stage("Pushing the helm charts to nexus") {
            steps {
                script {
                    withCredentials([string(credentialsId: 'docker_pass', variable: 'docker_password')]) {
                        dir('kubernetes/') {
                            sh '''
                                helmversion=$(helm show chart myapp | grep version | awk '/version:/ {print $2}' | tr -d '[:space:]')
                                tar -czvf myapp-${helmversion}.tgz myapp/
                                curl -u admin:$docker_password http://172.28.200.141:8081/repository/helm-hosted/ --upload-file myapp-${helmversion}.tgz -v
                            '''
                        }
                    }
                }
            }
        }

        // Stage 5: Approve Manually
        stage("Approve Manually") {
            steps {
                script {
                    timeout(time: 10, unit: 'MINUTES') {
                        // Send an email for manual approval and wait for input
                        mail bcc: '',
                            body: "<br>Project: ${env.JOB_NAME} <br>Build Number: ${env.BUILD_NUMBER} <br> Go to build url and approve the deployement request. <br> URL de build: ${env.BUILD_URL}",
                            cc: '',
                            charset: 'UTF-8',
                            from: 'saiidiikhaled@gmail.com',
                            mimeType: 'text/html',
                            replyTo: '',
                            subject: "${currentBuild.result} CI: Project name -> ${env.JOB_NAME}",
                            to: "saiidiikhaled@gmail.com";
                        input(id: "DeployGate", message: "Should I proceed to Deployment?", ok: 'Deploy')
                    }
                }
            }
        }

        // Stage 6: Deploying application on K8S cluster
        stage("Deploying application on K8S cluster") {
            steps {
                script {
                    withCredentials([string(credentialsId: 'docker_pass', variable: 'docker_password')]) {
                        dir('kubernetes/') {
                            // Check and delete existing Docker registry secret
                            def secretExists = sh(script: 'microk8s kubectl get secret registry-secret', returnStatus: true) == 0
                            if (secretExists) {
                                sh 'microk8s kubectl delete secret registry-secret'
                            }

                            // Create a new Docker registry secret
                            sh 'microk8s kubectl create secret docker-registry registry-secret \
                                --docker-server=172.28.200.141:8083 \
                                --docker-username=admin \
                                --docker-password=$docker_password \
                                --docker-email=khaled.saiidi@outlook.com'

                            // Check Docker login status
                            def dockerLoginStatus = sh(script: 'docker login -u admin -p $docker_password 172.28.200.141:8083', returnStatus: true)

                            // Proceed with deployment if Docker login is successful
                            if (dockerLoginStatus == 0) {
                                echo 'Docker login successful. Proceeding with deployment.'
                                // Deploy Helm chart
                                sh 'microk8s helm upgrade --install --set image.repository=172.28.200.141:8083/springapp --set image.tag=${VERSION} myjavaapp myapp/'
                            } else {
                                error 'Docker login failed. Aborting deployment.'
                            }
                        }
                    }
                }
            }
        }

        // Stage 7: Verifying App Deployment
        stage("Verifying App Deployment") {
            steps {
                script {
                    // Get the IP address of one of the nodes
                    def nodeIP = sh(script: 'microk8s kubectl get nodes -o jsonpath="{.items[0].status.addresses[0].address}"', returnStdout: true).trim()

                    // Run curl from within the pod using the node port
                    sh "microk8s kubectl run curl --image=curlimages/curl -i --rm --restart=Never -- curl ${nodeIP}:32522"
                }
            }
        }
    }
// Makee sure to expose Jenkins running on Internet using ngrok
    post {
        always {
            // Send a post-build email with project details
            mail bcc: '',
                body: "<br>Project: ${env.JOB_NAME} <br>Build Number: ${env.BUILD_NUMBER} <br> URL de build: ${env.BUILD_URL}",
                cc: '',
                charset: 'UTF-8',
                from: 'saiidiikhaled@gmail.com',
                mimeType: 'text/html',
                replyTo: '',
                subject: "${currentBuild.result} CI: Project name -> ${env.JOB_NAME}",
                to: "saiidiikhaled@gmail.com";
        }
    }
}
