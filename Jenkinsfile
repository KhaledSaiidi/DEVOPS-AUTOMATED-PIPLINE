pipeline{
    agent any
    stages{
        stage("Sonar Quality Check"){
            agent{
                docker {
                    image 'openjdk:17'
                }
            }
            steps{
                script{
                    sh 'apt-get update && apt-get install -y findutils'
                    withSonarQubeEnv(credentialsId: 'sonar-token') {
                        sh 'chmod +x gradlew'
                        sh './gradlew sonar --warning-mode all'
                    }
                }
            }
        }
    }
    post{
        always{
            echo "Success"
        }
    }
}