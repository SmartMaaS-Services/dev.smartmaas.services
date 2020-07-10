#!/bin/bash

version=1.0.0

#cli help function
helpFunction()
{
  echo ""
  echo -e "$(tput bold)$(tput setaf 3)This script will setup and deploy part1 services and configuration\nfrom the GIT repository on the working machine.\nPlease run script \"setup-part2.sh\" after successful completion of this script.$(tput sgr 0)\n"
  echo -e "Usage: $0 [--login-user <linux-login-user>] [--hub-user <dockerhub-username>] [--hub-pwd <dockerhub-password>]\n\t\t\t\t[--smtp-server <smtp-server>] [--smtp-user <smtp-user] [--smtp-pwd <smtp-password>]\n\t\t\t\t[--domain <domain-name>] [--stack <swarm-stack-name>]\n"
  echo -e "Mandatory parameters:-"
  echo -e "\t[--login-user]\tssh user"
  echo -e "\t[--hub-user]\tdockerhub username"
  echo -e "\t[--hub-pwd]\tdockerhub password"
  echo -e "\t[--smtp-server]\tSMTP server"
  echo -e "\t[--smtp-user]\tSMTP user"
  echo -e "\t[--smtp-pwd]\tSMTP password"
  echo -e "\t[--domain]\tdomain name"
  echo -e "\t[--stack]\tdocker Swarm stack name\n"
  echo -e "Optional parameters:-"
  echo -e "\t[--version]\tscript's version\n"
  echo -e "$(tput bold)$(tput setaf 5)Report bugs to: chandra.challagonda@fiware.org$(tput sgr 0)"
  echo -e "$(tput bold)$(tput setaf 5)License: FIWARE Foundation copyright@2020$(tput sgr 0)"
  exit 0
}

while (( $# > 0 ))
do
  opt="$1"
  shift
  case $opt in
  --help)
    helpFunction
    exit 0
    ;;
  --version)
    echo -e "$(tput bold)$(tput setaf 3)$version$(tput sgr 0)"
    exit 0
    ;;
  --login-user)
    USER="$1"
    shift
    ;;
  --hub-user)
    HUB_USER="$1"
    shift
    ;;
  --hub-pwd)
    HUB_PWD="$1"
    shift
    ;;
  --smtp-server)
    SMTP_SERVER="$1"
    shift
    ;;
  --smtp-user)
    SMTP_USER="$1"
    shift
    ;;
  --smtp-pwd)
    SMTP_PASS="$1"
    shift
    ;;
  --domain)
    DOMAIN="$1"
    shift
    ;;
  --stack)
    STACK="$1"
    shift
    ;;
  *)
    echo -e "$(tput bold)$(tput setaf 1)Usage: $0 [OPTIONS]...\nTry '$0 --help' for more information.$(tput sgr 0)"
    exit 1;
    ;;
  esac
done

if [ -z "${USER}" ] || [ -z "${HUB_USER}" ] || [ -z "${HUB_PWD}" ] || [ -z "${SMTP_SERVER}" ] || [ -z "${SMTP_USER}" ] || [ -z "${SMTP_PASS}" ] || [ -z "${DOMAIN}" ] || [ -z "${STACK}" ]
then
  echo -e "$(tput bold)$(tput setaf 1)Missing one of the mandatory options$(tput sgr 0)"
  echo -e "$(tput bold)$(tput setaf 2)Usage: $0 [OPTIONS]...\nTry '$0 --help' for more information.$(tput sgr 0)"
  exit 1
fi

#forming variables and creating directories
#CERT=/home/${USER}/certificates

#os updates and install softwares
echo -e "$(tput bold)$(tput setaf 3)Updating OS and installing softwares....$(tput sgr 0)"
sudo apt-get update -y && sudo apt-get upgrade -y && sudo apt-get install -y zip unzip
sudo apt install -y docker.io && sudo usermod -aG docker ${USER} && sudo systemctl start docker && sudo systemctl enable docker && sudo chown -R ${USER}:${USER} ~/.docker
sudo curl -L "https://github.com/docker/compose/releases/download/1.25.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose && sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
echo -e "$(tput bold)$(tput setaf 5)Successfully updated OS and installed required softwares$(tput sgr 0)"

#performing prerequisites
echo -e "$(tput bold)$(tput setaf 3)\nPerforming prerequisites....$(tput sgr 0)"
#mkdir -p ${CERT}
sudo bash -c 'echo "vm.max_map_count=262144" > /etc/sysctl.d/10-Docker-Services.conf' && sudo sysctl -p /etc/sysctl.d/10-Docker-Services.conf
grep -rl 'DOMAIN_NAME' * --exclude-dir scripts | xargs -i@ sed -i "s|DOMAIN_NAME|${DOMAIN}|g" @
#grep -rl 'WSDIR' * --exclude-dir scripts | xargs -i@ sed -i "s|WSDIR|${CERT}|g" @
grep -rl 'SMTP-SERVER' * --exclude-dir scripts | xargs -i@ sed -i "s|SMTP-SERVER|${SMTP_SERVER}|g" @
grep -rl 'SMTP-USER' * --exclude-dir scripts | xargs -i@ sed -i "s|SMTP-USER|${SMTP_USER}|g" @
grep -rl 'SMTP-PASS' * --exclude-dir scripts | xargs -i@ sed -i "s|SMTP-PASS|${SMTP_PASS}|g" @
#read password value from STDIN to prevent it from ending up in the shell’s history or log files
echo "${HUB_PWD}" | sudo docker login -u "${HUB_USER}" --password-stdin
echo -e "$(tput bold)$(tput setaf 5)Successfully performed pre-requisites$(tput sgr 0)"

#swarm mode and deployment of services in swarm - part1
echo -e "$(tput bold)$(tput setaf 3)\nDeploying services to docker swarm....$(tput sgr 0)"
sudo docker swarm init
sudo docker stack deploy -c services/mongo.yml -c services/nginx.yml -c services/mail.yml -c services/ngsiproxy.yml -c services/orion.yml -c services/quantumleap.yml ${STACK}
sudo docker stack deploy -c services/keyrock.yml -c services/umbrella.yml -c services/apinf.yml -c services/grafana.yml -c services/iotagent.yml -c services/iotagent-lora.yml ${STACK}
sudo docker stack deploy -c services/kurento.yml -c services/nifi.yml -c services/orion-ld.yml -c services/perseo.yml -c services/cosmos.yml -c services/cadvisor.yml ${STACK}
echo -e "$(tput bold)$(tput setaf 5)Successfully deployed all the services to docker swarm$(tput sgr 0)"
echo -e "$(tput bold)$(tput setaf 5)Create an umbrella user, get its api-key and auth-token and run setup-part2.sh script$(tput sgr 0)"
