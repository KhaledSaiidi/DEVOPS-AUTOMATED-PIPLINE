pipeline{
    agent any
    environment{
        VERSION = "${env.BUILD_ID}"
    }
    stages{
        stage("Sonar Quality Check"){
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

        stage("docker build & docker push"){
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
        
        stage("identifying misconfigs through Linting Helm Charts"){
            steps{
                script{
                    dir('kubernetes/') {
                        sh 'helm lint myapp'
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


        stage("Manual approval"){
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
                            sh 'kubectl create secret docker-registry registry-secret \
                            --docker-server=172.28.200.141:8083 \
                            --docker-username=admin \
                            --docker-password=$docker_password \
                            --docker-email=khaled.saiidi@outlook.com'
                            
                        // Deploy Helm chart
                            sh 'microk8s helm upgrade --install --set image.repository="172.28.200.141:8083/springapp" --set image.tag="${VERSION}" myjavaapp myapp/' 
                        }
                    }                
                }
            }
        }

        stage("Verifying App Deployement"){
            steps{
                script {
                    sh 'microk8s kubectl run curl --image=curlimages/curl -i --rm --restart=Never -- curl myjavaapp-myapp:8080'
                }
            }
        }
    }

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