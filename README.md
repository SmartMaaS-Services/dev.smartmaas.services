# Smart-Platform-Services

[![FIWARE Core Context Management](https://nexus.lab.fiware.org/static/badges/chapters/core.svg)](https://www.fiware.org/developers/catalogue/)
[![NGSI v2](https://nexus.lab.fiware.org/repository/raw/public/badges/specifications/ngsiv2.svg)](http://fiware-ges.github.io/orion/api/v2/stable/)
[![NGSI-LD badge](https://img.shields.io/badge/NGSI-LD-red.svg)](https://www.etsi.org/deliver/etsi_gs/CIM/001_099/009/01.02.01_60/gs_cim009v010201p.pdf)
[![](https://nexus.lab.fiware.org/repository/raw/public/badges/chapters/processing.svg)](./processing/README.md)
[![](https://nexus.lab.fiware.org/repository/raw/public/badges/chapters/visualization.svg)](./processing/README.md)
[![](https://nexus.lab.fiware.org/repository/raw/public/badges/chapters/media-streams.svg)](./processing/README.md)
[![](https://nexus.lab.fiware.org/repository/raw/public/badges/chapters/api-management.svg)](./data-publication/README.md)
[![](https://nexus.lab.fiware.org/repository/raw/public/badges/chapters/data-publication.svg)](./data-publication/README.md)
[![](https://nexus.lab.fiware.org/repository/raw/public/badges/chapters/data-monetization.svg)](./data-publication/README.md)
[![](https://nexus.lab.fiware.org/repository/raw/public/badges/chapters/security.svg)](./security/README.md)
[![License badge](https://img.shields.io/github/license/telefonicaid/fiware-orion.svg)](https://opensource.org/licenses/AGPL-3.0)

<b>Smart-Platform-Services</b> is a set of directories which contains Docker service YAMLs and configuration files of <b>FIWARE Foundation</b> Generic Enablers (GE) necessary to setup an initial Smart Platform.

## Content ##
- [Prerequisites](#prerequisites)
- [How to deploy?](#how-to-deploy)
- [Services incorporated](#services-incorporated)
- [Contribution](#contribution)
- [License](#license)

Smart-Platform-Services consists of two directories, `services` and `config`:

- `services` directory consists of all the Docker YAML files which contains instruction for the deployment of the GE
- `config` directory consists of all the configuration files needed by Docker services YAML files.

The whole stack is deployed and managed under a Docker Swarm Cluster.

<u><i>Note</i></u>: The following manual was written for deployments on Ubuntu/Debian-alike systems. The scripts were tested on a system with Ubuntu 18.04. No warranty can be given for compatibility with other versions or linux distributions.

## Prerequisites ##
Before you set up the platform on your VM or server, a few prerequisites must be fulfilled:

- you need a managable domain with the possibility of creating additional subdomains
- a Docker Hub account is required for pulling required Docker images. Go to [Docker Hub](https://hub.docker.com) to create an account.
- you must have a SMTP server ready for sending out e-mails to the platform users (register at a provider of your choice or set up a server on your own which won't be covered by this guide)
- make sure you can provide an e-mail address used by certbot (tool for setting up [Let's Encrypt](https://letsencrypt.org) certificates) for account registration and recovery
- allow incoming traffic on port 443 (HTTPS) on your VM

## How to deploy? ##

**Preperation of VM**

<div style="padding: 1em; border-radius: 0.4em; background: #F4F4F4;">
First of all, update/upgrade your VM and install some additional packages.

```bash
sudo apt-get update -y && sudo apt-get upgrade -y && sudo apt-get install -y zip unzip git
```

Deploy wildcard certificates from Let's Encrypt for your domain.  
Before executing the certbot command, please replace `<email>` with your e-mail address used for account registration and recovery of your certificates, e.g. `me@myexample.org`  
Please also change the placeholder `<domain-name>` to hold your domain name, e.g. `myexample.org`

```bash
sudo apt-get update -y && sudo apt-get install software-properties-common -y

sudo add-apt-repository universe -y && sudo add-apt-repository ppa:certbot/certbot -y && sudo apt-get update -y && sudo apt-get install certbot python-certbot-nginx -y

sudo certbot certonly --manual --preferred-challenges dns-01 --server https://acme-v02.api.letsencrypt.org/directory --email <email> --no-eff-email --manual-public-ip-logging-ok --agree-tos -d *.<domain-name>
```

After running the above command, add the DNS TXT record provided by Let’s Encrypt certbot to your DNS server.
</div>

**Step 1:**
<div style="padding: 1em; border-radius: 0.4em; background: #F4F4F4;">
Checkout this repository with your Git credentials.

```bash
git clone https://github.com/SmartMaaS-Services/dev.smartmaas.services.git
```
</div>

**Step 2:**
<div style="padding: 1em; border-radius: 0.4em; background: #F4F4F4;">
Change to your local repo directory. It currently contains two setup scripts for configuration and setup of the platform services. Be sure to have execution rights set for both scripts.

```bash
cd dev.smartmaas.services
chmod u+x scripts/setup-part*
```
Deploy services in Docker Swarm by running the first script. The following options are supported:

<pre>
<i>Mandatory options:</i>  
<b>--login-user</b>  logged-in (or SSH) user that will be added to the docker user group 
<b>--hub-user</b>    Docker Hub username  
<b>--hub-pwd</b>     Docker Hub password  
<b>--smtp-server</b> SMTP server address  
<b>--smtp-user</b>   SMTP account user  
<b>--smtp-pwd</b>    SMTP account password  
<b>--domain</b>      domain name  
<b>--stack</b>       stack name for the Docker Swarm - can be chosen freely  

<i>Optional options:</i> 
<b>--version</b>     prints out the script's version  
<b>--help</b>        prints out usage information and these options
</pre>

<u><i>Note</i></u>: Put option values into single quotes ('') to prevent special characters from being interpreted by the shell.

```bash
./scripts/setup-part1.sh --login-user '<linux-login-user>' --hub-user '<dockerhub-username>' --hub-pwd '<dockerhub-password>'
			 --smtp-server '<smtp-server>' --smtp-user '<smtp-user>' --smtp-pwd '<smtp-password>'
			 --domain '<domain-name>' --stack '<swarm-stack-name>'
```
</div>

**Step 3:** 
<div style="padding: 1em; border-radius: 0.4em; background: #F4F4F4;">
In your browser go to <b><i>umbrella.<code>&lt;domain-name&gt;</code>/admin</i></b> and register the first user (the admin). Note down the Auth-Token and set it instead of <code>&lt;admin-auth-token&gt;</code>. Also register yourself as "New API User" and note down the API-Key <code>&lt;api-key&gt;</code> for this user. Afterwards run the second deployment script.

<u><i>Note</i></u>: Also don't forget about the single quotes ('') here.

```bash
./scripts/setup-part2.sh --domain '<domain-name>' --api-key '<api-key>'
			 --token '<admin-auth-token>' --stack '<swarm-stack-name>'
```
</div>

## Services incorporated ##

<div style="padding: 1em; border-radius: 0.4em; background: #F4F4F4;">
mongo, nginx, mail, ngsiproxy, orion, quantumleap, keyrock, umbrella, apinf, tokenservice, tenant-manager, wirecloud, bae, cadvisor, ckan, grafana, iotagent, iotagent-lora, kurento, nifi, orion-ld, perseo, cosmos
</div>

## Contribution ##

Pull requests are welcome. Please make sure to update tests as appropriate.
Git conventions are being followed and changes go to development only from feature/bugfix branches.

## License ##

Smart-Platform-Services is licensed under Affero General Public License (GPL) version 3.

© 2020 FIWARE Foundation
