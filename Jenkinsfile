pipeline{
    agent any
    stages{
        stage("Sonar Quality Check"){
            steps{
                script{
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