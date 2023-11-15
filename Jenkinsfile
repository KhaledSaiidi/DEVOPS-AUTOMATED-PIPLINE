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
        
        stage("identifying misconfigs using datree in helm charts"){
            steps{
                script{
                    dir('kubernetes/') {
                        sh 'microk8s helm repo add datree-webhook https://datreeio.github.io/admission-webhook-datree'
                        sh 'microk8s helm repo update'
                        sh 'microk8s helm install -n datree datree-webhook datree-webhook/datree-admission-webhook --debug \
                        --create-namespace \
                        --set datree.token=GJdx2cP2TCDyUY3EhQKgTc \
                        --set datree.clusterName=$(kubectl config current-context)'
                        sh 'microk8s helm datree config set offline local'
                        sh 'microk8s helm datree test myapp/'
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