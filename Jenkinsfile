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

        stage("Deploying application on K8S cluster"){
            steps{
                script {
                    dir('kubernetes/') {
                        sh 'microk8s helm upgrade --install --set image.repository="172.28.200.141:8083/docker-hosted/v2/springapp" --set image.tag="${VERSION}" myjavaapp myapp/ ' 
                    } 
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