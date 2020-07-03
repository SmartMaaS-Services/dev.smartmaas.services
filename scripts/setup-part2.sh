#!/bin/bash

version=1.0.0

#cli help function
helpFunction()
{
  echo ""
  echo -e "$(tput bold)$(tput setaf 3)This script will setup and deploy part2 services and configuration\nfrom the provided GIT repository on the working machine.\nThis script should be run only after successfull execution of \"setup-part1.sh\" script.\n$(tput sgr 0)"
  echo -e "Usage: $0 [--domain <domain-name>] [--api-key <api-key>]\n\t\t\t\t[--token <admin-auth-token>] [--stack <swarm-stack-name>]\n"
  echo -e "Mandatory options:-"
  echo -e "\t[--domain]\tdomain name"
  echo -e "\t[--api-key]\tAPI key of the first created umbrella user"
  echo -e "\t[--token]\tadmin auth token of the first created umbrella user"
  echo -e "\t[--stack]\tdocker swarm stack name\n"
  echo -e "$(tput bold)$(tput setaf 5)Report bugs to: artoo.detoo@profirator.fi$(tput sgr 0)"
  echo -e "$(tput bold)$(tput setaf 5)License: Profirator copyright@2020$(tput sgr 0)"
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
  --domain)
    DOMAIN="$1"
    shift
    ;;
  --api-key)
    API_KEY="$1"
    shift
    ;;
  --token)
    TOKEN="$1"
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

if [ -z "${DOMAIN}" ] || [ -z "${API_KEY}" ] || [ -z "${TOKEN}" ] || [ -z "${STACK}" ]
then
  echo -e "$(tput bold)$(tput setaf 1)Missing one of the mandatory options$(tput sgr 0)"
  echo -e "$(tput bold)$(tput setaf 2)Usage: $0 [OPTIONS]...\nTry '$0 --help' for more information.$(tput sgr 0)"
  exit 1
fi

#Pre-requisites
IDM_USERID="admin"
IDM_EMAIL="admin@test.com"
IDM_PWD="1234"

#Adding Website Backends in umbrella
echo -e "$(tput bold)$(tput setaf 3)Adding website backends in umbrella$(tput sgr 0)"
frontend_host=(${DOMAIN} accounts.${DOMAIN} apis.${DOMAIN} cadvisor.${DOMAIN} charts.${DOMAIN} dashboards.${DOMAIN} data.${DOMAIN} knowage.${DOMAIN} market.${DOMAIN} ngsiproxy.${DOMAIN} nifi.${DOMAIN} perseo.${DOMAIN} umbrella.${DOMAIN})
backend_server=(nginx keyrock apinf cadvisor grafana wirecloudnginx ckan knowage bae ngsiproxy nifi perseo-fe nginx)
backend_protocol=(80 3000 3000 8085 3000 80 5000 8083 8004 3000 8080 9090 80)

for (( i=0; i<${#frontend_host[@]}; i++ )) do
  for j in ${backend_server[$i]}; do
    for k in ${backend_protocol[$i]}; do
      echo -e "\n\nAdding website backend for the domain ${frontend_host[$i]} $j $k"
      website_backend_id=$(curl -s -X POST --header "Content-Type: application/json" --header "Accept: application/json" -d "{ \
        \"website_backend\": { \
          \"frontend_host\": \"${frontend_host[$i]}\", \
          \"backend_protocol\": \"http\", \
          \"server_host\": \"$j\", \
          \"server_port\": $k \
        } \
      }" "https://umbrella.${DOMAIN}/api-umbrella/v1/website_backends.json" \
      -H "X-Api-Key: ${API_KEY}" \
      -H "X-Admin-Auth-Token: ${TOKEN}"|python -mjson.tool|grep '"id":'|awk -F": " '{print $2}'|tr -d '",\r')
      echo -e "publishing changes for the domain ${frontend_host[$i]}"
      curl -s -X POST --header "Content-Type: application/json" --header "Accept: application/json" -d "{ \
        \"config\": { \
          \"website_backends\": { \
            \"${website_backend_id}\": { \
              \"publish\": \"1\" \
            } \
          } \
        } \
      }" "https://umbrella.${DOMAIN}/api-umbrella/v1/config/publish.json" \
      -H "X-Api-Key: ${API_KEY}" \
      -H "X-Admin-Auth-Token: ${TOKEN}"
    done
  done
done
echo -e "$(tput bold)$(tput setaf 5)\nSuccessfully added website backends in umbrella$(tput sgr 0)"

#Adding applications to IDM and replace dummy clientid and secret for applications
sleep 5
echo -e "$(tput bold)$(tput setaf 3)\nAdding applications to IDM$(tput sgr 0)"
idm_token=$(curl -s --include \
                  --request POST \
                  --header "Content-Type: application/json" \
                  --data-binary "{
                    \"name\": \"${IDM_EMAIL}\",
                    \"password\": \"${IDM_PWD}\"
                  }" \
                  "https://accounts.${DOMAIN}/v1/auth/tokens"|grep "x-subject-token"|awk -F": " '{print $2}'|tr -d '\r')

echo -e "Adding IDM application API Access"
app1_id=$(curl -s \
              --request POST \
              --header "Content-Type: application/json" \
              --header "X-Auth-token: ${idm_token}" \
              --data-binary "{
                \"application\": {
                  \"name\": \"API Access\",
                  \"description\": \"OAuth2 Application used to control access to internal services like the Context Broker, the STH data, the CEP, ...services\",
                  \"url\": \"https://${DOMAIN}\",
                  \"redirect_uri\": \"https://${DOMAIN}\",
                  \"grant_type\": [
                    \"authorization_code\",
                    \"implicit\",
                    \"password\"
                  ],
                  \"token_types\": [
                    \"jwt\",
                    \"permanent\"
                  ]
        	      }
              }" \
          "https://accounts.${DOMAIN}/v1/applications"|python -mjson.tool|grep '"id":'|awk -F": " '{print $2}'|tr -d '",\r')
echo -e "Getting app. secret"
app1_secret=$(curl -s \
                  --header "X-Auth-token: ${idm_token}" \
              "https://accounts.${DOMAIN}/v1/applications/${app1_id}"|python -mjson.tool|grep '"secret":'|awk -F": " '{print $2}'|tr -d '",\r')
echo -e "Adding roles"
app1_roles=(tenant-admin data-provider data-consumer iot-admin)
for (( i=0; i<${#app1_roles[@]}; i++ )) do
  curl -s \
        --request POST \
        --header "Content-Type: application/json" \
        --header "X-Auth-token: ${idm_token}" \
        --data-binary "{
          \"role\": {
            \"name\": \"${app1_roles[$i]}\"
          }
        }" \
  "https://accounts.${DOMAIN}/v1/applications/${app1_id}/roles"
done
echo "\nReplacing API_ACCESS_ID and API_ACCESS_SECRET in the repo."
grep -rl 'API_ACCESS_ID' * --exclude-dir scripts | xargs -i@ sed -i "s/API_ACCESS_ID/${app1_id}/g" @
grep -rl 'API_ACCESS_SECRET' * --exclude-dir scripts | xargs -i@ sed -i "s/API_ACCESS_SECRET/${app1_secret}/g" @

echo -e "\n\nAdding IDM application API Catalogue"
app2_id=$(curl -s \
              --request POST \
              --header "Content-Type: application/json" \
              --header "X-Auth-token: ${idm_token}" \
              --data-binary "{
                \"application\": {
                  \"name\": \"API Catalogue\",
                  \"description\": \"Catalogue of APIs provided using Profirator\",
                  \"url\": \"https://apis.${DOMAIN}\",
                  \"redirect_uri\": \"https://apis.${DOMAIN}/_oauth/fiware\",
                  \"grant_type\": [
                    \"authorization_code\",
                    \"implicit\",
                    \"password\"
                  ],
                  \"token_types\": [
                    \"jwt\",
                    \"permanent\"
                  ]
                }
              }" \
          "https://accounts.${DOMAIN}/v1/applications"|python -mjson.tool|grep '"id":'|awk -F": " '{print $2}'|tr -d '",\r')
echo -e "Adding roles"
app2_roles=(tenant-admin data-provider data-consumer)
for (( i=0; i<${#app2_roles[@]}; i++ )) do
  curl -s \
        --request POST \
        --header "Content-Type: application/json" \
        --header "X-Auth-token: ${idm_token}" \
        --data-binary "{
          \"role\": {
            \"name\": \"${app2_roles[$i]}\"
          }
        }" \
  "https://accounts.${DOMAIN}/v1/applications/${app2_id}/roles"
done

echo -e "\n\nAdding IDM application Wirecloud"
app3_id=$(curl -s \
              --request POST \
              --header "Content-Type: application/json" \
              --header "X-Auth-token: ${idm_token}" \
              --data-binary "{
                \"application\": {
                  \"name\": \"Wirecloud\",
                  \"description\": \"Wirecloud dashboard portal\",
                  \"url\": \"https://dashboards.${DOMAIN}\",
                  \"redirect_uri\": \"https://dashboards.${DOMAIN}/complete/fiware/\",
                  \"grant_type\": [
                    \"authorization_code\",
                    \"implicit\",
                    \"password\"
                  ]
                }
              }" \
          "https://accounts.${DOMAIN}/v1/applications"|python -mjson.tool|grep '"id":'|awk -F": " '{print $2}'|tr -d '",\r')
echo -e "Getting app. secret"
app3_secret=$(curl -s \
                  --header "X-Auth-token: ${idm_token}" \
              "https://accounts.${DOMAIN}/v1/applications/${app3_id}"|python -mjson.tool|grep '"secret":'|awk -F": " '{print $2}'|tr -d '",\r')
echo -e "Adding roles"
app3_roles=(admin)
for (( i=0; i<${#app3_roles[@]}; i++ )) do
  curl -s \
        --request POST \
        --header "Content-Type: application/json" \
        --header "X-Auth-token: ${idm_token}" \
        --data-binary "{
          \"role\": {
            \"name\": \"${app3_roles[$i]}\"
          }
        }" \
  "https://accounts.${DOMAIN}/v1/applications/${app3_id}/roles"
done
echo -e "\nReplacing WIRECLOUD_ID and WIRECLOUD_SECRET in the repo."
grep -rl 'WIRECLOUD_ID' * --exclude-dir scripts | xargs -i@ sed -i "s/WIRECLOUD_ID/${app3_id}/g" @
grep -rl 'WIRECLOUD_SECRET' * --exclude-dir scripts | xargs -i@ sed -i "s/WIRECLOUD_SECRET/${app3_secret}/g" @

echo -e "\n\nAdding IDM application BAE"
app4_id=$(curl -s \
              --request POST \
              --header "Content-Type: application/json" \
              --header "X-Auth-token: ${idm_token}" \
              --data-binary "{
                \"application\": {
                  \"name\": \"Market\",
                  \"description\": \"Market service provided by the Business API Ecosystem\",
                  \"url\": \"https://market.${DOMAIN}\",
                  \"redirect_uri\": \"https://market.${DOMAIN}/auth/fiware/callback\",
                  \"grant_type\": [
                    \"authorization_code\",
                    \"implicit\",
                    \"password\"
                  ]
                }
              }" \
          "https://accounts.${DOMAIN}/v1/applications"|python -mjson.tool|grep '"id":'|awk -F": " '{print $2}'|tr -d '",\r')
echo -e "Getting app. secret"
app4_secret=$(curl -s \
                  --header "X-Auth-token: ${idm_token}" \
              "https://accounts.${DOMAIN}/v1/applications/${app4_id}"|python -mjson.tool|grep '"secret":'|awk -F": " '{print $2}'|tr -d '",\r')
echo -e "Adding roles"
app4_roles=(seller customer orgAdmin admin data-provider data-consumer)
for (( i=0; i<${#app4_roles[@]}; i++ )) do
  curl -s \
        --request POST \
        --header "Content-Type: application/json" \
        --header "X-Auth-token: ${idm_token}" \
        --data-binary "{
          \"role\": {
            \"name\": \"${app4_roles[$i]}\"
          }
        }" \
  "https://accounts.${DOMAIN}/v1/applications/${app4_id}/roles"
done
echo -e "\nReplacing BAE_ID and BAE_SECRET in the repo."
grep -rl 'BAE_ID' * --exclude-dir scripts | xargs -i@ sed -i "s/BAE_ID/${app4_id}/g" @
grep -rl 'BAE_SECRET' * --exclude-dir scripts | xargs -i@ sed -i "s/BAE_SECRET/${app4_secret}/g" @

echo "\n\nAdding IDM application CKAN"
app5_id=$(curl -s \
              --request POST \
              --header "Content-Type: application/json" \
              --header "X-Auth-token: ${idm_token}" \
              --data-binary "{
                \"application\": {
                  \"name\": \"CKAN\",
                  \"description\": \"Generic Enabler CKAN Extensions\",
                  \"url\": \"https://${DOMAIN}\",
                  \"redirect_uri\": \"https://data.${DOMAIN}/oauth2/callback\",
                  \"grant_type\": [
                    \"authorization_code\",
                    \"implicit\",
                    \"password\"
                  ]
                }
              }" \
          "https://accounts.${DOMAIN}/v1/applications"|python -mjson.tool|grep '"id":'|awk -F": " '{print $2}'|tr -d '",\r')
echo -e "Getting app. secret"
app5_secret=$(curl -s \
                  --header "X-Auth-token: ${idm_token}" \
              "https://accounts.${DOMAIN}/v1/applications/${app5_id}"|python -mjson.tool|grep '"secret":'|awk -F": " '{print $2}'|tr -d '",\r')
echo -e "Adding roles"
app5_roles=(admin)
for (( i=0; i<${#app5_roles[@]}; i++ )) do
  curl -s \
        --request POST \
        --header "Content-Type: application/json" \
        --header "X-Auth-token: ${idm_token}" \
        --data-binary "{
          \"role\": {
            \"name\": \"${app5_roles[$i]}\"
          }
        }" \
  "https://accounts.${DOMAIN}/v1/applications/${app5_id}/roles"
done
echo -e "\nReplacing CKAN_ID and CKAN_SECRET in the repo."
grep -rl 'CKAN_ID' * --exclude-dir scripts | xargs -i@ sed -i "s/CKAN_ID/${app5_id}/g" @
grep -rl 'CKAN_SECRET' * --exclude-dir scripts | xargs -i@ sed -i "s/CKAN_SECRET/${app5_secret}/g" @

echo -e "\n\nAdding IDM application Knowage"
app6_id=$(curl -s \
              --request POST \
              --header "Content-Type: application/json" \
              --header "X-Auth-token: ${idm_token}" \
              --data-binary "{
                \"application\": {
                  \"name\": \"Knowage\",
                  \"description\": \"IDM and Knowage integration\",
                  \"url\": \"https://knowage.${DOMAIN}/knowage/servlet/AdapterHTTP?PAGE=LoginPage\",
                  \"redirect_uri\": \"https://knowage.${DOMAIN}/knowage/servlet/AdapterHTTP?PAGE=LoginPage\",
                  \"grant_type\": [
                    \"authorization_code\",
                    \"implicit\",
                    \"password\"
                  ]
                }
              }" \
          "https://accounts.${DOMAIN}/v1/applications"|python -mjson.tool|grep '"id":'|awk -F": " '{print $2}'|tr -d '",\r')
echo -e "Getting app. secret"
app6_secret=$(curl -s \
                  --header "X-Auth-token: ${idm_token}" \
              "https://accounts.${DOMAIN}/v1/applications/${app6_id}"|python -mjson.tool|grep '"secret":'|awk -F": " '{print $2}'|tr -d '",\r')
echo -e "Adding roles"
app6_roles=(DEV USER ADMIN)
for (( i=0; i<${#app6_roles[@]}; i++ )) do
  curl -s \
        --request POST \
        --header "Content-Type: application/json" \
        --header "X-Auth-token: ${idm_token}" \
        --data-binary "{
          \"role\": {
            \"name\": \"${app6_roles[$i]}\"
          }
        }" \
  "https://accounts.${DOMAIN}/v1/applications/${app6_id}/roles"
done
echo -e "\nReplacing KNOWAGE_ID and KNOWAGE_SECRET in the repo."
grep -rl 'KNOWAGE_ID' * --exclude-dir scripts | xargs -i@ sed -i "s/KNOWAGE_ID/${app6_id}/g" @
grep -rl 'KNOWAGE_SECRET' * --exclude-dir scripts | xargs -i@ sed -i "s/KNOWAGE_SECRET/${app6_secret}/g" @

echo -e "\nReplacing IDM_USERID, IDM_EMAIL, and IDM_PWD in the repo."
grep -rl 'IDM_USERID' * --exclude-dir scripts | xargs -i@ sed -i "s/IDM_USERID/${IDM_USERID}/g" @
email_files=$(grep -rl 'IDM_EMAIL' * --exclude-dir scripts)
for i in $email_files
do
        sed -i "s/IDM_EMAIL/${IDM_EMAIL}/g" $i
done
grep -rl 'IDM_PWD' * --exclude-dir scripts | xargs -i@ sed -i "s/IDM_PWD/${IDM_PWD}/g" @
echo -e "$(tput bold)$(tput setaf 5)Successfully added applications to IDM$(tput sgr 0)"

#deployment of services in swarm - part2
sleep 5
echo -e "$(tput bold)$(tput setaf 3)\nDeploying remaining services to docker swarm....$(tput sgr 0)"
sudo docker stack deploy -c services/tokenservice.yml -c services/tenant-manager.yml -c services/wirecloud.yml ${STACK}
sudo docker stack deploy -c services/bae.yml -c services/ckan.yml -c services/knowage.yml ${STACK}
echo -e "$(tput bold)$(tput setaf 5)Successfully deployed services to docker swarm$(tput sgr 0)"