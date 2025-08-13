# Requirements

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.10.5
- [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html#installing-and-upgrading-ansible) >= 2.18.3
- [Docker](https://docs.docker.com/engine/install/) >= 28.0.0
- [Docker Compose](https://docs.docker.com/compose/install/) >= 2.33.1
- [AWS](console.aws.amazon.com) account
    - Resources: VPC, EC2, DynamoDB
    - Regions: `us-east-1`, `ap-southeast-1`

# Deployment

## Prepare Environment

Generate a new access key in the [AWS Console](http://console.aws.amazon.com/iam/home#/security_credentials), if you don't already have one

Set up your `~/.aws/credentials` (to be used by Terraform)

```zsh
AWS_ACCESS_KEY_ID=<access_key>
AWS_SECRET_ACCESS_KEY=<secret_access_key>
```

Copy `infra/env/.env.template` into a new `infra/env/us.env`, add your AWS credentials (key and secret key) and set the region as `us-east-1` (to be used by Ansible). The content should have something like:

```zsh
AWS_ACCESS_KEY_ID=<access_key>
AWS_SECRET_ACCESS_KEY=<secret_access_key>
AWS_REGION=us-east-1
```

Copy `infra/env/.env.template` into a new `infra/env/ap.env`, add your AWS credentials (key and secret key) and set the region as `ap-southeast-1` (to be used by Ansible). The content should have something like:

```zsh
AWS_ACCESS_KEY_ID=<access_key>
AWS_SECRET_ACCESS_KEY=<secret_access_key>
AWS_REGION=ap-southeast-1
```

## Deploy Infrastructure

Deploy EC2 instances and DynamoDB table (commented for now):

```zsh
cd infra/terraform
terraform init
terraform apply
```

Configure and deploy app and database

```zsh
cd infra/ansible
ansible-playbook -i inventory.ini playbooks/provision.yml

ansible-playbook -i inventory.ini playbooks/docker_swarm_start.yml

ansible-playbook -i inventory.ini playbooks/couchdb_start.yml
ansible-playbook -i inventory.ini playbooks/couchdb_configure.yml
ansible-playbook -i inventory.ini playbooks/couchdb_test.yml

ansible-playbook -i inventory.ini playbooks/app_deploy.yml
ansible-playbook -i inventory.ini playbooks/app_start.yml

ansible-playbook -i inventory.ini playbooks/client_register_users.yml
```

Restart or clean everything

```zsh
cd infra/ansible
ansible-playbook -i inventory.ini playbooks/docker_swarm_stop.yml
ansible-playbook -i inventory.ini playbooks/app_stop.yml
ansible-playbook -i inventory.ini playbooks/clean.yml

cd infra/terraform
terraform destroy
```

## Run Experiments

Experiment 1:
```zsh
cd infra/ansible
ansible-playbook -i inventory.ini playbooks/client_register_movies_info.yml
ansible-playbook -i inventory.ini playbooks/client_compose_reviews.yml
ansible-playbook -i inventory.ini playbooks/client_read_movie_info.yml
ansible-playbook -i inventory.ini playbooks/client_read_page.yml
```

Experiment 2:
```zsh
cd infra/ansible
ansible-playbook -i inventory.ini playbooks/client_register_movies_info_read_page.yml
```

Others:
```zsh
cd infra/ansible
ansible-playbook -i inventory.ini playbooks/client_register_movies.yml
```

The playbooks will gather the clients logs and save them into the `logs/` directory.

# Additional Content

## Connect to Clients (Automated)

Connect to each client:
```zsh
cd infra
./ssh_node.sh manager
./ssh_node.sh us
./ssh_node.sh ap
```

## Run Clients Scripts Manually

In each client machine, schedule the script to run at a given time in the near future
```zsh
date
echo '/home/ubuntu/dsb-mediamicroservices/client_register_movies_info.sh > /home/ubuntu/client_register_movies_info.log 2>&1' | at 22:27
```

Check the log files:

```zsh
cat /home/ubuntu/client_register_movies_info.log
```

## Build MediaMicroservices Image

If docker username is changed then change docker image name in `DeathStarBench/mediaMicroservices/docker-compose.yml` accordingly:

```zsh
cd DeathStarBench/mediaMicroservices
docker build -t mafaldacf/media-microservices .
docker push mafaldacf/media-microservices
```
