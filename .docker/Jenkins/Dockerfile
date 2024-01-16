# Jenkins JDK 17, JDK 11 is being deprecated
FROM jenkins/jenkins:latest-jdk17

USER root

RUN apt-get update && apt-get install -y curl git

RUN curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh

RUN usermod -aG docker jenkins

RUN apt update && apt install tzdata -y

ENV TZ="Asia/Dhaka"

USER jenkins