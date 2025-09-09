pipeline {
  agent any
  environment {
    DOCKER_REPO = "YOUR_DOCKERHUB_USERNAME/ecommerce"
    DEPLOY_USER = "ubuntu"             // change to remote ssh user
    DEPLOY_HOST = "YOUR_DEPLOY_HOST"   // change to remote host/IP
    DEPLOY_DIR  = "/home/ubuntu/ecommerce" // where .env will live on deploy host
  }
  stages {
    stage('Checkout') {
      steps { checkout scm }
    }
    stage('Install & Build') {
      steps {
        sh 'npm ci'
        sh 'npm run build'
      }
    }
    stage('Build Docker') {
      steps {
        script {
          sh "docker build -t ${DOCKER_REPO}:${env.BUILD_ID} ."
          sh "docker tag ${DOCKER_REPO}:${env.BUILD_ID} ${DOCKER_REPO}:latest"
        }
      }
    }
    stage('Docker Login & Push') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
          sh 'echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin'
          sh "docker push ${DOCKER_REPO}:${env.BUILD_ID}"
          sh "docker push ${DOCKER_REPO}:latest"
        }
      }
    }
    stage('Deploy to Remote') {
      steps {
        // Requires "SSH Agent" plugin and an SSH private key credential with id 'ssh-deploy-key'
        sshagent (credentials: ['ssh-deploy-key']) {
          // Pull image, stop/remove old container, run new container (assumes remote has docker)
          sh """
            ssh -o StrictHostKeyChecking=no ${DEPLOY_USER}@${DEPLOY_HOST} '
              mkdir -p ${DEPLOY_DIR}
              cd ${DEPLOY_DIR}
              docker pull ${DOCKER_REPO}:${env.BUILD_ID} || exit 0
              docker stop ecommerce || true
              docker rm ecommerce || true
              docker run -d --name ecommerce -p 3000:3000 --env-file ${DEPLOY_DIR}/.env ${DOCKER_REPO}:${env.BUILD_ID}
            '
          """
        }
      }
    }
  }
  post {
    always {
      sh 'docker image prune -f || true'
    }
  }
}
