# Jenkins controller image using JDK 21
FROM jenkins/jenkins:2.555.1-lts-jdk21

USER root

RUN set -eux; \
  if [ -f /etc/apt/sources.list ]; then \
    sed -i 's|http://deb.debian.org/debian|https://deb.debian.org/debian|g' /etc/apt/sources.list; \
  fi; \
  find /etc/apt/sources.list.d -type f \( -name '*.list' -o -name '*.sources' \) -print0 | \
    xargs -0 -r sed -i 's|http://deb.debian.org/debian|https://deb.debian.org/debian|g'; \
  apt-get -o Acquire::Retries=5 update; \
  apt-get install -y --no-install-recommends curl ca-certificates; \
  rm -rf /var/lib/apt/lists/*

RUN curl -fsSLo /usr/share/keyrings/docker-archive-keyring.asc \
  https://download.docker.com/linux/debian/gpg

RUN set -eux; \
  . /etc/os-release; \
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.asc] https://download.docker.com/linux/debian ${VERSION_CODENAME} stable" > /etc/apt/sources.list.d/docker.list

RUN apt-get -o Acquire::Retries=5 update && apt-get install -y --no-install-recommends docker-ce-cli && rm -rf /var/lib/apt/lists/*

RUN apt update && apt install tzdata -y

ENV TZ="Asia/Dhaka"

USER jenkins