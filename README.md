[![HitCount](https://hits.dwyl.com/aburaihan-dev/jenkins-in-docker.svg?style=flat-square)](http://hits.dwyl.com/aburaihan-dev/jenkins-in-docker)

# jenkins-in-docker

Blog Posts: 
- Part-1: [Step-by-Step Guide to Setting Up Jenkins on Docker with Docker Agent-Based Builds](https://dev.to/msrabon/step-by-step-guide-to-setting-up-jenkins-on-docker-with-docker-agent-based-builds-43j5)

# Jenkins Docker Setup

This repository provides Docker resources for running a Jenkins controller and SSH agent with Docker Compose.

## Getting Started

Follow these steps to get Jenkins up and running using Docker:

### Prerequisites

- Ensure that Docker is installed on your machine. If not, you can download and install Docker from [Docker's official website](https://www.docker.com/get-started).
- Ensure that Docker Compose v2 is available as `docker compose`.

### Usage

1. Clone this repository to your local machine:

   ```bash
   git clone https://github.com/aburaihan-dev/jenkins-in-docker.git
   cd jenkins-in-docker

   ```
2. Generate an SSH keypair for the Jenkins agent connection:
   ```bash
   export AGENT_SSH_DIR="jenkins-agent-ssh-key" && mkdir -p ${AGENT_SSH_DIR} && ssh-keygen -t rsa -b 4096 -f ./${AGENT_SSH_DIR}/id_rsa
   ```

3. Copy the example environment file and add the generated public key:
   ```bash
   cp .env.example .env
   printf 'JENKINS_AGENT_SSH_PUBKEY="%s"\n' "$(cat ./${AGENT_SSH_DIR}/id_rsa.pub)" > .env
   ```

   Or run the helper script to generate the key, update `.env`, and choose a mode plus deploy target:
   ```bash
   ./start-jenkins.sh
   ```

   `./start-jenkins.sh` builds and starts both services.
   `./start-jenkins.sh build jenkins` only builds the Jenkins controller image.
   `./start-jenkins.sh build jenkins-agent` only builds the agent image.
   `./start-jenkins.sh start both` starts or restarts both services, and builds missing images first.
   `./start-jenkins.sh start jenkins` starts or restarts only the Jenkins controller.
   `./start-jenkins.sh start jenkins-agent` starts or restarts only the agent.
   `./start-jenkins.sh stop both` stops both running containers.

   More examples:
   ```bash
   ./start-jenkins.sh
   # Generate the key if needed, then build and start both services

   ./start-jenkins.sh build both
   # Build both images without starting containers

   ./start-jenkins.sh default jenkins
   # Build and start only the Jenkins controller on port 8080

   ./start-jenkins.sh start jenkins-agent
   # Restart only the SSH agent after changing its image or env config

      ./start-jenkins.sh stop jenkins
      # Stop only the Jenkins controller container
   ```

4. Build and start the stack:
   ```bash
   docker compose up -d --build
   ```

5. Access Jenkins in your browser by navigating to http://localhost:8080 and complete the initial setup.

6. In Jenkins, configure an SSH agent that connects to `jenkins-agent` on port `22` using the private key at `./${AGENT_SSH_DIR}/id_rsa`.

## Security Notes

- The Jenkins controller runs as `root` and has access to the host Docker socket so that jobs can run Docker builds. Treat this setup as a trusted local or lab environment, not a hardened production deployment.
- The compose file now fails fast if `JENKINS_AGENT_SSH_PUBKEY` is missing so the agent does not start with an empty authorized key list.

## Customization
You can customize the Jenkins configuration by modifying `docker-compose.yaml`, `.env`, or the Dockerfiles based on your specific requirements.

## Contributing
Feel free to contribute to this project by opening issues or submitting pull requests. Your feedback and contributions are highly appreciated.

## License
This project is licensed under the [MIT License](https://github.com/git/git-scm.com/blob/main/MIT-LICENSE.txt).
