pipeline{
    agent any
    environment{
        VERSION = "${env.BUILD_ID}"
    }
    stages{

        stage("SonarQube Code Check"){
            steps{
                script{
                    withSonarQubeEnv(credentialsId: 'sonar-token') {
                        sh 'chmod +x gradlew'
                        sh './gradlew sonar'
                    }
                    timeout(time: 1, unit: 'HOURS') {
                        def qg = waitForQualityGate()
                        if(qg.status != 'OK') {
                            error "Pipline aborted due to quality gate failure: ${qg.status}"
                        }
                    }
                }
            }
        }


        stage("docker build/push images"){
            steps{
                script {
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


        stage("identifying mis-configuration with Datreee.io/Linting"){
            steps{
                script{
                    dir('kubernetes/') {
                        sh 'microk8s helm lint myapp'
                    }
                }
            }
        }

        stage("Pushing the helm charts to nexus"){
            steps{
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

        stage("Approve Manually"){
            steps{
                script {
                    timeout(time: 10, unit: 'MINUTES') {
                      mail bcc: '', 
                        body: "<br>Project: ${env.JOB_NAME} <br>Build Number: ${env.BUILD_NUMBER} <br> Go to build url and approve the deployement request. <br> URL de build: ${env.BUILD_URL}", 
                        cc: '', 
                        charset: 'UTF-8', 
                        from: 'saiidiikhaled@gmail.com',
                        mimeType: 'text/html', 
                        replyTo: '', 
                        subject: "${currentBuild.result} CI: Project name -> ${env.JOB_NAME}", 
                        to: "saiidiikhaled@gmail.com";
                        input(id: "DeployGate", message: "Should i proceed to Deployement ?", ok: 'Deploy')
                    }
                }
            }
        }

        stage("Deploying application on K8S cluster"){
            steps{
                script {
                    withCredentials([string(credentialsId: 'docker_pass', variable: 'docker_password')]) {
                        dir('kubernetes/') {
                         // Check if the secret exists
                         def secretExists = sh(script: 'microk8s kubectl get secret registry-secret', returnStatus: true) == 0
                        // If the secret exists, delete it
                        if (secretExists) {
                        sh 'microk8s kubectl delete secret registry-secret'
                        }

                        // Create the Docker registry secret
                            sh 'microk8s kubectl create secret docker-registry registry-secret \
                            --docker-server=172.28.200.141:8083 \
                            --docker-username=admin \
                            --docker-password=$docker_password \
                            --docker-email=khaled.saiidi@outlook.com'
                            
                        // Create the Docker registry secret
                        def dockerLoginStatus = sh(script: 'docker login -u admin -p $docker_password 172.28.200.141:8083', returnStatus: true)

                        // Check if Docker login was successful
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

        stage("Verifying App Deployement"){
            steps{
                script {
                    // Get the IP address of one of the nodes
                def nodeIP = sh(script: 'microk8s kubectl get nodes -o jsonpath="{.items[0].status.addresses[0].address}"', returnStdout: true).trim()
                // Run curl from within the pod using the node port
                sh "microk8s kubectl run curl --image=curlimages/curl -i --rm --restart=Never -- curl ${nodeIP}:32522"
                }
            }
        }
    }
//add ngrok for exposing jenkins Ip address to Internet then use it in the gthub webhook with GHPR builder in jenkins
    post {
    always {
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