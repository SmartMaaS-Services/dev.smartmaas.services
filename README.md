# Docker-Services

Docker-Services is a set of directories which contains docker "service yamls" and "configuration" files of **Profirator** Generic Enablers(GE) necessary to setup an initial smart platform.

**Docker-Services** consists of two directories viz. "services" and "config"

- "services" directory consists of all the docker yaml files which contains instruction for the deployment of GE.
- "config" folder consists of all the configuration files needed by docker services yaml files.

The whole stack is deployed and managed under **Docker Swarm Cluster**

## How to Deploy?

**Step 1:** Checkout the repo with your credentials
```
git clone https://github.com/SmartMaaS-Services/dev.smartmaas.services/Docker-Services.git
```

**Step 2:** Deploy the services in docker swarm by running the script
```
cd Docker-Services

./scripts/setup-part1.sh [--login-user <linux-login-user>] [--hub-user <dockerhub-username>] [--hub-pwd <dockerhub-password>]
			 [--smtp-server <smtp-server>] [--smtp-user <smtp-user] [--smtp-pwd <smtp-password>]
			 [--domain <domain-name>] [--email <email>] [--stack <swarm-stack-name>]
```

**Step 3:** Get umbrella api-key and token and run the second deployment script
```
Login to "umbrella.<domain>/signups" and register the first user. Note down the api-key and token

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
