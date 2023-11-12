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
                        sh 'chmod +x gradlew'
                        sh './gradlew clean'
                        sh './gradlew build'
                        sh './gradlew tasks'
                        sh './gradlew sonar'
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