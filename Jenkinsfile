pipeline {
  agent {
    docker {
      image 'node:9-alpine'
      args '-p 3000:3000'
    }
  }
  environment {
    CI = 'true'
    JWT_KEY_FILE = credentials('jwt-secret-key')
    SFDC_SCRATCH_ORG_USERNAME = ''
    SFDC_DEV_HUB_USERNAME = credentials('devhub-auth-username')
    SFDC_DEV_HUB_LOGIN_URL = credentials('devhub-login-url')
    SDFC_DEV_HUB_CLIENT_ID = credentials('devhub-connected-app-consumer-key')
  }
  stages {
    stage('Install SFDX') {
      steps {
        sh '''apk update
apk add --no-cache bash ca-certificates wget
update-ca-certificates
node --version
npm i npm@latest -g
npm install sfdx-cli --global
sfdx --version
sfdx plugins --core'''
      }
    }
    stage('Auth Dev Hub') {
      steps {
        sh 'sfdx force:auth:jwt:grant --clientid $SDFC_DEV_HUB_CLIENT_ID --username $SFDC_DEV_HUB_USERNAME --jwtkeyfile $JWT_KEY_FILE --setdefaultdevhubusername --instanceurl $SFDC_DEV_HUB_LOGIN_URL'
      }
    }
    stage('Create Scratch Org') {
      steps {
        sh 'sfdx force:org:create --definitionfile config/project-scratch-def.json --json --setdefaultusername'
      }
    }
  }
}
