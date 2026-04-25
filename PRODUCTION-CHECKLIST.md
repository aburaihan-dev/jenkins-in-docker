# Jenkins-in-Docker Production Checklist

This checklist is for preparing and operating the stack in a controlled release process.

## 1) Pre-Release Validation

- Confirm Docker and Docker Compose are available on the host.
- Confirm the operator user can access Docker daemon without sudo.
- Confirm `.env` exists and contains `JENKINS_AGENT_SSH_PUBKEY`.
- Confirm required files are present:
  - `docker-compose.yaml`
  - `.docker/Jenkins/Dockerfile`
  - `.docker/Agent/Dockerfile`
  - `start-jenkins.sh`
- Confirm script syntax:
  - bash -n start-jenkins.sh
- Confirm compose resolves:
  - docker compose config

## 2) Build and Deploy (Controlled)

- Build only:
  - ./start-jenkins.sh build both
- Start or restart services:
  - ./start-jenkins.sh start both
- Or one-shot build + start:
  - ./start-jenkins.sh default both

## 3) Post-Deploy Verification

- Check running containers:
  - docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"
- Check network attachments:
  - docker network inspect jenkins-network
- Check controller health/logs:
  - docker logs --tail 100 jenkins-jdk-21
- Check agent health/logs:
  - docker logs --tail 100 jenkins-ssh-agent
- Verify agent SSH host key (for Jenkins node config with manual key verification):
  - docker exec jenkins-ssh-agent cat /etc/ssh/ssh_host_rsa_key.pub

## 4) Jenkins Functional Verification

- Open Jenkins UI at http://localhost:8080.
- Ensure configured node can connect to host `jenkins-agent`, port `22`.
- Use private key from `jenkins-agent-ssh-key/id_rsa` in credentials.
- Run a small Docker-based pipeline and verify:
  - docker version succeeds in agent steps
  - docker run works in pipeline stages

## 5) Data Backup (Before Changes/Upgrade)

Create backup directory:
- mkdir -p backups

Backup named volumes:
- docker run --rm -v jenkins_home:/source -v "$PWD/backups:/backup" alpine:3.20 sh -c "cd /source && tar -czf /backup/jenkins_home_$(date +%F_%H%M%S).tgz ."
- docker run --rm -v jenkins-ssh-agent:/source -v "$PWD/backups:/backup" alpine:3.20 sh -c "cd /source && tar -czf /backup/jenkins_ssh_agent_$(date +%F_%H%M%S).tgz ."
- docker run --rm -v jenkins-agent-ssh-host-keys:/source -v "$PWD/backups:/backup" alpine:3.20 sh -c "cd /source && tar -czf /backup/jenkins_agent_ssh_host_keys_$(date +%F_%H%M%S).tgz ."

Backup environment and key materials:
- cp -a .env backups/.env.$(date +%F_%H%M%S)
- cp -a jenkins-agent-ssh-key backups/jenkins-agent-ssh-key.$(date +%F_%H%M%S)

## 6) Restore (Disaster Recovery)

Stop services:
- ./start-jenkins.sh stop both

Restore volume snapshot example (`jenkins_home`):
- docker run --rm -v jenkins_home:/target -v "$PWD/backups:/backup" alpine:3.20 sh -c "cd /target && rm -rf ./* && tar -xzf /backup/<jenkins_home_backup_file>.tgz"

Repeat restore for:
- jenkins-ssh-agent volume
- jenkins-agent-ssh-host-keys volume

Restore env/key files if required:
- cp backups/<env_backup_file> .env
- cp -a backups/<key_backup_dir> jenkins-agent-ssh-key

Start services:
- ./start-jenkins.sh start both

## 7) Rollback Procedure

Use rollback if a new image/build causes instability.

- Stop services:
  - ./start-jenkins.sh stop both
- Revert code/config to last known good git tag/commit.
- Rebuild images from reverted code:
  - ./start-jenkins.sh build both
- Start reverted stack:
  - ./start-jenkins.sh start both
- Validate with Post-Deploy Verification section.

## 8) Release Sign-off Criteria

- Controller and agent containers are healthy and stable for 15+ minutes.
- Jenkins node connects to `jenkins-agent` with expected host key strategy.
- At least one full demo pipeline run is green.
- No unresolved errors in container logs related to SSH, Docker socket, or filesystem permissions.
- Recent backup artifacts are present and tested for extraction.

## 9) Known Non-Blocking Warning

- Office365 connector webhook HTTP 400 is external notification configuration related.
- This does not block core build execution if pipeline stages are passing.
