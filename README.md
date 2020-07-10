# Docker-Services

Docker-Services is a set of directories which contains docker "service yamls" and "configuration" files of **FIWARE Foundation** Generic Enablers(GE) necessary to setup an initial smart platform.

**Docker-Services** consists of two directories viz. "services" and "config"

- "services" directory consists of all the docker yaml files which contains instruction for the deployment of GE.
- "config" folder consists of all the configuration files needed by docker services yaml files.

The whole stack is deployed and managed under **Docker Swarm Cluster**

## How to Deploy?
**Preperation of VM**
Update the VM
```
sudo apt-get update -y && sudo apt-get upgrade -y && sudo apt-get install -y zip unzip git
```

Deploy Wild Card Certificates from Lets Encrypt for the Domain
```
sudo apt-get update -y && sudo apt-get install software-properties-common -y

sudo add-apt-repository universe -y && sudo add-apt-repository ppa:certbot/certbot -y && sudo apt-get update -y && sudo apt-get install certbot python-certbot-nginx -y

sudo certbot certonly --manual --preferred-challenges dns-01 --server https://acme-v02.api.letsencrypt.org/directory --email <email> --no-eff-email --manual-public-ip-logging-ok --agree-tos -d *.<domain-name>
```

Deploy a DNS TXT record provided by Let’s Encrypt certbot after running the above command.

**Step 1:** Checkout the repo with your credentials
```
git clone https://github.com/SmartMaaS-Services/dev.smartmaas.services.git
```

**Step 2:** Deploy the services in docker swarm by running the script
```
cd Docker-Services

./scripts/setup-part1.sh [--login-user <linux-login-user>] [--hub-user <dockerhub-username>] [--hub-pwd <dockerhub-password>]
			 [--smtp-server <smtp-server>] [--smtp-user <smtp-user] [--smtp-pwd <smtp-password>]
			 [--domain <domain-name>] [--stack <swarm-stack-name>]
```

**Step 3:** Get umbrella api-key and token and run the second deployment script
```
Login to "umbrella.<domain>/admin" and register the first user. Note down the Admin API Token <admin-auth-token>. Register yourself as "New API User" and note down the API Key <api-key>.
	

./scripts/setup-part2.sh [--domain <domain-name>] [--api-key <api-key>]
			 [--token <admin-auth-token>] [--stack <swarm-stack-name>]
```

## Services incorporated
```
mongo, nginx, mail, ngsiproxy, orion, quantumleap, keyrock, umbrella, apinf, tokenservice, tenant-manager, wirecloud, bae, cadvisor, ckan, grafana, iotagent, iotagent-lora, kurento, nifi, orion-ld, perseo, cosmos
```

## Contributing

Pull requests are welcome. Please make sure to update tests as appropriate.
Git conventions are being followed and changes go to the develop only from feature/bugfix branches.

## License

FIWARE Foundation copyright@2020
