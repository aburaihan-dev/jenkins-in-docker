#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: ./start-jenkins.sh [default|build|start|stop] [jenkins|jenkins-agent|both]

Generates the Jenkins agent SSH key if needed, writes JENKINS_AGENT_SSH_PUBKEY
to .env, then runs one of these modes:

  default   Generate/update config, build images, and start the stack
  build     Generate/update config and build images only
  start     Generate/update config and start or restart the stack
  stop      Stop running containers for the selected target

Deploy targets:
  jenkins        Operate on the Jenkins controller only
  jenkins-agent  Operate on the Jenkins SSH agent only
  both           Operate on both services (default)

Optional environment variables:
  AGENT_SSH_DIR   Directory for the SSH keypair (default: jenkins-agent-ssh-key)
  ENV_FILE        Environment file to update (default: .env)

Examples:
  ./start-jenkins.sh
    Generate/update config, then build and start both services

  ./start-jenkins.sh build jenkins
    Only build the Jenkins controller image

  ./start-jenkins.sh start jenkins-agent
    Start or restart only the SSH agent container

  ./start-jenkins.sh default jenkins
    Build and start only the Jenkins controller

  ./start-jenkins.sh stop both
    Stop both running containers without rebuilding images
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

mode="${1:-default}"
target="${2:-both}"

case "$mode" in
  default|build|start|stop)
    ;;
  *)
    echo "Unknown mode: $mode" >&2
    usage >&2
    exit 1
    ;;
esac

case "$target" in
  jenkins)
    compose_services=(jenkins)
    image_names=(jenkins-jdk-21)
    container_names=(jenkins-jdk-21)
    ;;
  jenkins-agent)
    compose_services=(jenkins-agent)
    image_names=(jenkins-ssh-agent-jdk-21)
    container_names=(agent)
    ;;
  both)
    compose_services=(jenkins jenkins-agent)
    image_names=(jenkins-jdk-21 jenkins-ssh-agent-jdk-21)
    container_names=(jenkins-jdk-21 agent)
    ;;
  *)
    echo "Unknown deploy target: $target" >&2
    usage >&2
    exit 1
    ;;
esac

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
agent_ssh_dir="${AGENT_SSH_DIR:-jenkins-agent-ssh-key}"
env_file="${ENV_FILE:-.env}"
agent_dir_path="${repo_dir}/${agent_ssh_dir}"
env_file_path="${repo_dir}/${env_file}"
private_key_path="${agent_dir_path}/id_rsa"
public_key_path="${private_key_path}.pub"

require_command() {
  local command_name="$1"

  if ! command -v "$command_name" >/dev/null 2>&1; then
    echo "Missing required command: $command_name" >&2
    exit 1
  fi
}

require_command docker

if ! docker compose version >/dev/null 2>&1; then
  echo "Docker Compose v2 is required and must be available as 'docker compose'." >&2
  exit 1
fi

prepare_agent_env() {
  require_command ssh-keygen

  mkdir -p "$agent_dir_path"

  if [[ ! -f "$private_key_path" || ! -f "$public_key_path" ]]; then
    rm -f "$private_key_path" "$public_key_path"
    ssh-keygen -q -t rsa -b 4096 -N "" -f "$private_key_path"
    echo "Generated SSH keypair in ${agent_ssh_dir}/"
  else
    echo "Using existing SSH keypair in ${agent_ssh_dir}/"
  fi

  public_key_contents="$(<"$public_key_path")"
  tmp_env_file="$(mktemp)"

  cleanup() {
    rm -f "$tmp_env_file"
  }

  trap cleanup EXIT

  if [[ -f "$env_file_path" ]]; then
    grep -v '^JENKINS_AGENT_SSH_PUBKEY=' "$env_file_path" > "$tmp_env_file" || true
  fi

  printf 'JENKINS_AGENT_SSH_PUBKEY="%s"\n' "$public_key_contents" >> "$tmp_env_file"
  mv "$tmp_env_file" "$env_file_path"
  chmod 600 "$env_file_path"
  chown "$(id -u):$(id -g)" "$env_file_path"

  echo "Updated ${env_file} with the Jenkins agent public key"
}

ensure_images_exist() {
  local missing_images=()
  local image_name

  for image_name in "${image_names[@]}"; do
    if ! docker image inspect "$image_name" >/dev/null 2>&1; then
      missing_images+=("$image_name")
    fi
  done

  if [[ ${#missing_images[@]} -gt 0 ]]; then
    echo "Missing local images for ${target}: ${missing_images[*]}"
    echo "Building ${target} images before start"
    docker compose build "${compose_services[@]}"
  fi
}

stop_selected_containers() {
  local container_name
  local stopped_any=false

  for container_name in "${container_names[@]}"; do
    if docker container inspect "$container_name" >/dev/null 2>&1; then
      echo "Stopping container: ${container_name}"
      docker stop "$container_name" >/dev/null
      stopped_any=true
    fi
  done

  if [[ "$stopped_any" == false ]]; then
    echo "No running containers found for ${target}"
  fi
}

if [[ "$mode" != "stop" ]]; then
  prepare_agent_env
fi

cd "$repo_dir"

case "$mode" in
  default)
    echo "Building and starting ${target} with Docker Compose"
    docker compose up -d --build "${compose_services[@]}"
    ;;
  build)
    echo "Building ${target} images with Docker Compose"
    docker compose build "${compose_services[@]}"
    ;;
  start)
    ensure_images_exist
    echo "Starting or restarting ${target} with Docker Compose"
    docker compose up -d --force-recreate "${compose_services[@]}"
    ;;
  stop)
    echo "Stopping ${target} containers"
    stop_selected_containers
    ;;
esac

if [[ "$mode" != "build" && "$mode" != "stop" && "$target" != "jenkins-agent" ]]; then
  echo "Jenkins is starting at http://localhost:8080"
fi

echo "Use ${agent_ssh_dir}/id_rsa as the SSH private key for the Jenkins agent connection"