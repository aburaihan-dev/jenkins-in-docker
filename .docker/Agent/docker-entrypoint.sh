#!/usr/bin/env bash

set -euo pipefail

# Match docker.sock group inside the container so SSH sessions as jenkins can use Docker.
if [[ -S /var/run/docker.sock ]]; then
  sock_gid="$(stat -c '%g' /var/run/docker.sock)"

  if ! getent group "$sock_gid" >/dev/null; then
    groupadd -g "$sock_gid" docker-host >/dev/null 2>&1 || true
  fi

  group_name="$(getent group "$sock_gid" | cut -d: -f1 || true)"
  if [[ -n "$group_name" ]]; then
    usermod -aG "$group_name" jenkins >/dev/null 2>&1 || true
  fi
fi

exec setup-sshd
