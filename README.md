# Requirements

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.10.5
- [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html#installing-and-upgrading-ansible) >= 2.18.3
- [Docker](https://docs.docker.com/engine/install/) >= 28.0.0
- [Docker Compose](https://docs.docker.com/compose/install/) >= 2.33.1
- [GCP account (recommended)](console.cloud.google.com) OR [AWS account](console.aws.amazon.com)

# Set Up Cloud Credentials

## Option 1 (Recommended): GCP

Generate a new service account key in the [GCP Console](http://console.cloud.google.com/iam-admin/serviceaccounts), if you don't already have one, and save it into `infra/providers/gcp/credentials.json`.

Make sure your gcp ssh public key is present in `~/.ssh/google_compute_engine.pub`.

Go to `infra/terraform/gcp/variables.tf` and change any parameter if needed.

## Option 2: AWS

Generate a new access key in the [AWS Console](http://console.aws.amazon.com/iam/home#/security_credentials), if you don't already have one.

Set up your `~/.aws/credentials` (to be used by Terraform):

```zsh
AWS_ACCESS_KEY_ID=<access_key>
AWS_SECRET_ACCESS_KEY=<secret_access_key>
```

Copy `infra/providers/aws/.env.template` into a new `infra/env/us.env`, add your AWS credentials (key and secret key) and set the region as `us-east-1` (to be used by Ansible).


Copy `infra/providers/aws/.env.template` into a new `infra/env/ap.env`, add your AWS credentials (key and secret key) and set the region as `ap-southeast-1` (to be used by Ansible).

# Deploy Infrastructure

## Option 1 (Recommended): GCP

Deploy Compute Engine machines:

```zsh
cd infra/terraform/gcp
terraform init
terraform apply
```

## Option 2: AWS

Deploy EC2 instances and DynamoDB table (commented for now):

```zsh
cd infra/terraform/aws
terraform init
terraform apply
```

# Provision and Configure Cluster

```zsh
cd infra/ansible
ansible-playbook playbooks/deploy.yml
```

# Run Experiments

```zsh
ansible-playbook playbooks/experiment_1.yml
ansible-playbook playbooks/experiment_2.yml
ansible-playbook playbooks/experiment_3.yml
```

The playbooks will gather the clients logs and save them into the `logs/` directory.

# Restart and Clean Resources

Use as needed:

```zsh
ansible-playbook playbooks/restart.yml
```

```zsh
ansible-playbook playbooks/clean.yml
```

```zsh
cd infra/terraform
terraform destroy
```

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
