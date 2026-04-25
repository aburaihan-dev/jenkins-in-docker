pipeline {
  agent { label 'docker-build-agent-1' }

  options {
    timestamps()
    disableConcurrentBuilds()
    buildDiscarder(logRotator(numToKeepStr: '20'))
    timeout(time: 30, unit: 'MINUTES')
  }

  environment {
    CI = 'true'
  }

  stages {
    stage('Docker Access Check') {
      steps {
        sh '''
          set -eux
          whoami
          id
          docker version
          docker info
        '''
      }
    }

    stage('Normalize Workspace Permissions') {
      steps {
        sh '''
          set -eux
          docker run --rm -u root:root \
            -v "$PWD":/workspace \
            -w /workspace \
            alpine:3.20 \
            sh -c 'chown -R 1000:1000 /workspace && chmod -R u+rwX /workspace'
        '''
      }
    }

    stage('Create Demo App') {
      agent {
        docker {
          image 'node:20-alpine'
          args '--user root:root'
          reuseNode true
        }
      }
      steps {
        sh '''
          set -eux

          cat > package.json <<'JSON'
{
  "name": "demo-pipeline",
  "version": "1.0.0",
  "description": "Declarative Jenkins pipeline demo",
  "private": true,
  "scripts": {
    "test": "node test.js",
    "build": "node build.js"
  },
  "dependencies": {
    "lodash": "^4.17.21"
  }
}
JSON

          cat > index.js <<'JS'
const _ = require('lodash');

function sum(a, b) {
  return a + b;
}

console.log('Build demo app initialized:', _.camelCase('jenkins demo app'));

module.exports = { sum };
JS

          cat > test.js <<'JS'
const { sum } = require('./index');

if (sum(2, 3) !== 5) {
  throw new Error('sum(2, 3) should equal 5');
}

console.log('All tests passed');
JS

          mkdir -p dist
          cat > build.js <<'JS'
const fs = require('fs');
const path = require('path');

const outFile = path.join('dist', 'build-info.txt');
const content = [
  `build_time=${new Date().toISOString()}`,
  `build_number=${process.env.BUILD_NUMBER || 'local'}`,
  `job_name=${process.env.JOB_NAME || 'local-job'}`
].join(String.fromCharCode(10));

fs.writeFileSync(outFile, content + String.fromCharCode(10), 'utf8');
console.log(`Created ${outFile}`);
JS

          node -e 'JSON.parse(require("fs").readFileSync("package.json", "utf8"))'
        '''
      }
    }

    stage('Install Dependencies') {
      agent {
        docker {
          image 'node:20-alpine'
          args '--user root:root'
          reuseNode true
        }
      }
      steps {
        sh 'npm install --no-audit --no-fund'
      }
    }

    stage('Run Tests') {
      agent {
        docker {
          image 'node:20-alpine'
          args '--user root:root'
          reuseNode true
        }
      }
      steps {
        sh 'npm test'
      }
    }

    stage('Build') {
      agent {
        docker {
          image 'node:20-alpine'
          args '--user root:root'
          reuseNode true
        }
      }
      steps {
        sh 'npm run build'
      }
    }

    stage('Normalize Ownership') {
      steps {
        sh '''
          set -eux
          docker run --rm -u root:root \
            -v "$PWD":/workspace \
            -w /workspace \
            alpine:3.20 \
            sh -c 'chown -R 1000:1000 /workspace && chmod -R u+rwX /workspace'
        '''
      }
    }

    stage('Archive Artifacts') {
      steps {
        archiveArtifacts artifacts: 'dist/**,package.json,package-lock.json,index.js,test.js,build.js', fingerprint: true
      }
    }
  }

  post {
    always {
      sh '''
        set +e
        docker run --rm -u root:root \
          -v "$PWD":/workspace \
          -w /workspace \
          alpine:3.20 \
          sh -c 'chown -R 1000:1000 /workspace && chmod -R u+rwX /workspace'
      '''
      cleanWs(deleteDirs: true, disableDeferredWipeout: true, notFailBuild: true)
    }
    success {
      echo 'Pipeline completed successfully.'
    }
    failure {
      echo 'Pipeline failed. Check stage logs for details.'
    }
  }
}
