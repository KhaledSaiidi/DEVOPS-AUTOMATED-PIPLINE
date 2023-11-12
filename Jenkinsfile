pipeline{
    agent any
    stages{
        stage("Sonar Quality Check"){
            agent{
                docker {
                    image 'openjdk:17'
                    args '-u root' // Use root user for more privileges (if necessary)
                }
            }
            steps{
                script{
                    withSonarQubeEnv(credentialsId: 'sonar-token') {
                        sh 'xargs --version'
                        sh 'chmod +x gradlew'
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