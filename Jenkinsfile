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
    }
}