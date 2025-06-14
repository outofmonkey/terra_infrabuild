pipeline {
    agent any
    environment {
        AWS_REGION = "us-east-1"
    }
    stages {
        stage('Checkout') {
            steps {
                echo "Checking out code"
                git branch: 'main', credentialsId: 'github-creds', url: 'https://github.com/outofmonkey/terra_infrabuild.git'
            }
        }
        stage('Install Terraform') {
            steps {
                echo "Checking for Terraform installation"
                sh '''
                    if ! command -v terraform >/dev/null 2>&1; then
                        echo "Terraform not found, installing..."
                        sudo apt-get update
                        sudo apt-get install -y gnupg software-properties-common
                        wget -qO- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
                        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
                        sudo apt-get update
                        sudo apt-get install -y terraform
                        terraform --version
                    else
                        echo "Terraform already installed"
                        terraform --version
                    fi
                '''
            }
        }
        stage('Terraform Init') {
            steps {
                echo "Initializing Terraform"
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-access-key', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY']]) {
                    sh 'terraform init || { echo "Terraform init failed"; exit 1; }'
                }
            }
        }
        stage('Terraform Plan') {
            steps {
                echo "Running Terraform plan"
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-access-key', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY']]) {
                    sh 'terraform plan -out=tfplan || { echo "Terraform plan failed"; exit 1; }'
                }
            }
        }
        stage('Terraform Apply') {
            steps {
                echo "Applying Terraform changes"
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-access-key', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY']]) {
                    sh 'terraform apply -auto-approve tfplan || { echo "Terraform apply failed"; exit 1; }'
                }
            }
        }
        stage('Terraform Output') {
            steps {
                echo "Retrieving Terraform outputs"
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-access-key', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY']]) {
                    sh '''
                        echo ALB: $(terraform output alb_dns_name)
                        echo Bastion: $(terraform output bastion_public_ip)
                    '''
                }
            }
        }
    }
    post {
        success {
            echo "Pipeline completed successfully"
        }
        failure {
            echo "Pipeline failed"
        }
        always {
            echo "Cleaning workspace"
            cleanWs()
        }
    }
}