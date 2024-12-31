[![HitCount](https://hits.dwyl.com/aburaihan-dev/jenkins-in-docker.svg?style=flat-square)](http://hits.dwyl.com/aburaihan-dev/jenkins-in-docker)

# jenkins-in-docker

Blog Posts: 
- Part-1: [Step-by-Step Guide to Setting Up Jenkins on Docker with Docker Agent-Based Builds](https://dev.to/msrabon/step-by-step-guide-to-setting-up-jenkins-on-docker-with-docker-agent-based-builds-43j5)

# Jenkins Docker Setup

This repository provides Docker resources for setting up Jenkins using Docker. It includes a Dockerfile and a docker-compose.yml file to simplify the process of running Jenkins in a containerized environment.

## Getting Started

Follow these steps to get Jenkins up and running using Docker:

### Prerequisites

- Ensure that Docker is installed on your machine. If not, you can download and install Docker from [Docker's official website](https://www.docker.com/get-started).

### Usage

1. Clone this repository to your local machine:

   ```bash
   git clone https://github.com/aburaihan-dev/jenkins-in-docker.git
   cd jenkins-docker-setup

   ```
2. Build the Jenkins Docker image:
   ```bash
   docker build -t jenkins-docker .
   ```
4. Start Jenkins using Docker Compose:
   ```bash
   docker-compose up -d
   ```
6. Access Jenkins in your browser by navigating to http://localhost:8080. Follow the on-screen instructions to complete the setup.

## Generate SSH-key for connecting with Jenkins Agent via SSH
```bash
export AGENT_SSH_DIR="jenkins-agent-ssh-key" && mkdir -p ${AGENT_SSH_DIR} && ssh-keygen -t rsa -b 4096 -f ./${AGENT_SSH_DIR}/id_rsa
```

## Customization
You can customize the Jenkins configuration by modifying the docker-compose.yml file or the Dockerfile based on your specific requirements.

## Contributing
Feel free to contribute to this project by opening issues or submitting pull requests. Your feedback and contributions are highly appreciated.

## License
This project is licensed under the [MIT License](https://github.com/git/git-scm.com/blob/main/MIT-LICENSE.txt).
