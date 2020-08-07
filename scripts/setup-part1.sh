#!/bin/bash

version=1.0.0

#cli help function
helpFunction()
{
  echo ""
  echo -e "$(tput bold)$(tput setaf 3)This script will setup and deploy part 1 of the platfom services and configuration\nfrom the Git repository on this machine.\nIMPORTANT: Please run script \"setup-part2.sh\" ONLY AFTER successful completion of this script.$(tput sgr 0)\n"
  echo -e "Usage: $0 --login-user '<linux-login-user>' --hub-user '<dockerhub-username>' --hub-pwd '<dockerhub-password>'\n\t\t\t--smtp-server '<smtp-server>' --smtp-user '<smtp-user>' --smtp-pwd '<smtp-password>'\n\t\t\t--domain '<domain-name>' --stack '<swarm-stack-name>'\n"
  echo -e "Mandatory options:"
  echo -e "\t--login-user\tlogged-in (or SSH) user that will be added to the docker user group"
  echo -e "\t--hub-user\tDocker Hub username"
  echo -e "\t--hub-pwd\tDocker Hub password"
  echo -e "\t--smtp-server\tSMTP server address"
  echo -e "\t--smtp-user\tSMTP account user"
  echo -e "\t--smtp-pwd\tSMTP account password"
  echo -e "\t--domain\tdomain name"
  echo -e "\t--stack\t\tstack name for the Docker Swarm - can be chosen freely\n"
  echo -e "Optional options:"
  echo -e "\t--version\tprints out the script's version"
  echo -e "\t--version\tprints out these help and usage information\n"
  echo -e "$(tput bold)$(tput setaf 5)Report bugs to: chandra.challagonda@fiware.org$(tput sgr 0)"
  echo -e "$(tput bold)$(tput setaf 5)License: AGPL-3.0, (c) 2020 FIWARE Foundation$(tput sgr 0)"
  echo -e "\n"
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

#update OS and install required software
echo -e "$(tput bold)$(tput setaf 3)\nUpdating OS and installing required software...$(tput sgr 0)"
sudo apt-get update -y && sudo apt-get upgrade -y && sudo apt-get install -y zip unzip
sudo apt install -y docker.io && sudo usermod -aG docker ${USER} && sudo systemctl start docker && sudo systemctl enable docker && sudo chown -R ${USER}:${USER} ~/.docker
sudo curl -L "https://github.com/docker/compose/releases/download/1.25.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose && sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
echo -e "$(tput bold)$(tput setaf 5)Successfully updated OS and installed required software$(tput sgr 0)"

#configuring required settings
echo -e "$(tput bold)$(tput setaf 3)\nConfiguring some required settings...$(tput sgr 0)"
#mkdir -p ${CERT}
sudo bash -c 'echo "vm.max_map_count=262144" > /etc/sysctl.d/10-Docker-Services.conf' && sudo sysctl -p /etc/sysctl.d/10-Docker-Services.conf
grep -rl 'DOMAIN_NAME' * --exclude-dir scripts | xargs sed -i "s|DOMAIN_NAME|${DOMAIN}|g"
#grep -rl 'WSDIR' * --exclude-dir scripts | xargs sed -i "s|WSDIR|${CERT}|g"
grep -rl 'SMTP-SERVER' * --exclude-dir scripts | xargs sed -i "s|SMTP-SERVER|${SMTP_SERVER}|g"
grep -rl 'SMTP-USER' * --exclude-dir scripts | xargs sed -i "s|SMTP-USER|${SMTP_USER}|g"
grep -rl 'SMTP-PASS' * --exclude-dir scripts | xargs sed -i "s|SMTP-PASS|${SMTP_PASS}|g"
#read password value from STDIN to prevent it from ending up in the shell’s history or log files
echo "${HUB_PWD}" | sudo docker login -u "${HUB_USER}" --password-stdin
echo -e "$(tput bold)$(tput setaf 5)Successfully configured settings$(tput sgr 0)"

#swarm mode and deployment of services to Docker Swarm (part 1)
echo -e "$(tput bold)$(tput setaf 3)\nDeploying services to Docker Swarm...$(tput sgr 0)"
sudo docker swarm init
sudo docker stack deploy -c services/mongo.yml -c services/nginx.yml -c services/mail.yml -c services/ngsiproxy.yml -c services/orion.yml -c services/quantumleap.yml ${STACK}
sudo docker stack deploy -c services/keyrock.yml -c services/umbrella.yml -c services/apinf.yml -c services/grafana.yml -c services/iotagent.yml -c services/iotagent-lora.yml ${STACK}
sudo docker stack deploy -c services/kurento.yml -c services/nifi.yml -c services/orion-ld.yml -c services/perseo.yml -c services/cosmos.yml -c services/cadvisor.yml ${STACK}
echo -e "$(tput bold)$(tput setaf 5)Successfully deployed all the services to Docker Swarm$(tput sgr 0)"
echo -e "$(tput bold)$(tput setaf 5)Next step: Create an API Umbrella admin and another user, get their API-Keys and run setup-part2.sh script$(tput sgr 0)"
echo -e "\n"
