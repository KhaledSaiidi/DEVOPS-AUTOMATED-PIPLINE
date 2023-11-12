pipeline{
    agent any
    stages{
        stage("Sonar Quality Check"){
            agent{
                docker {
                    image 'openjdk:11'
                }
            }
            steps{
                script{
                    withSonarQubeEnv(credentialsId: 'sonar-token') {
                        docker.image('openjdk:17').inside {
                        sh 'chmod +x gradlew'
                        sh './gradlew sonarqube --warning-mode all'
                        }
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