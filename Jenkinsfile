pipeline {
  agent {
    docker {
      image 'node:9-alpine'
      args '-p 3000:3000'
    }

  }
  stages {
    stage('Install SFDX') {
      steps {
        sh '''wget https://developer.salesforce.com/media/salesforce-cli/sfdx-linux-amd64.tar.xz
mkdir sfdx
tar xJf sfdx-linux-amd64.tar.xz -C sfdx --strip-components 1
./sfdx/install'''
      }
    }
  }
  environment {
    CI = 'true'
  }
}