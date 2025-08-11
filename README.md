# Requirements

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.10.5
- [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html#installing-and-upgrading-ansible) >= 2.18.3
- [Docker](https://docs.docker.com/engine/install/) >= 28.0.0
- [Docker Compose](https://docs.docker.com/compose/install/) >= 2.33.1
- [AWS](console.aws.amazon.com) account 

# Deployment

## Prepare Environment

1. Generate a new access key in the [AWS Console](http://console.aws.amazon.com/iam/home#/security_credentials), if you don't already have one

1. Set up your `~/.aws/credentials` (to be used by Terraform)

    ```zsh
    AWS_ACCESS_KEY_ID=<access_key>
    AWS_SECRET_ACCESS_KEY=<secret_access_key>
    ```

2. Copy `infra/env/.env.template` into a new `infra/env/us.env`, add your AWS credentials (key and secret key) and set the region as `us-east-1` (to be used by Ansible). The content should have something like:

    ```zsh
    AWS_ACCESS_KEY_ID=<access_key>
    AWS_SECRET_ACCESS_KEY=<secret_access_key>
    AWS_REGION=us-east-1
    ```

3. Copy `infra/env/.env.template` into a new `infra/env/ap.env`, add your AWS credentials (key and secret key) and set the region as `ap-southeast-1` (to be used by Ansible). The content should have something like:

    ```zsh
    AWS_ACCESS_KEY_ID=<access_key>
    AWS_SECRET_ACCESS_KEY=<secret_access_key>
    AWS_REGION=ap-southeast-1
    ```

## Deploy Infrastructure

Deploy DynamoDB table and EC2 instances:

```zsh
cd infra/terraform
terraform init
terraform apply
terraform destroy # at the end
```

Configure and initialize app

```zsh
cd infra/ansible
ansible-playbook -i inventory.ini playbooks/app_deploy.yml
ansible-playbook -i inventory.ini playbooks/app_start.yml
ansible-playbook -i inventory.ini playbooks/app_clean.yml # when restarting or at the end
ansible-playbook -i inventory.ini playbooks/client_register_users.yml
```

## Run Clients

Experiment 1:

```zsh
cd infra/ansible
ansible-playbook -i inventory.ini playbooks/client_register_movies_ids.yml
```

Experiment 2:
```zsh
cd infra/ansible
ansible-playbook -i inventory.ini playbooks/client_register_movies_partial.yml
ansible-playbook -i inventory.ini playbooks/client_read_movie_info.yml
```

Experiment 3:
```zsh
cd infra/ansible
ansible-playbook -i inventory.ini playbooks/client_register_movies_complete.yml
ansible-playbook -i inventory.ini playbooks/client_read_movie_info.yml

ansible-playbook -i inventory.ini playbooks/client_compose_review.yml
ansible-playbook -i inventory.ini playbooks/client_read_page.yml
```


The playbook will gather the clients logs and save them into the `infra/logs/` directory.

## OPTIONAL: Run Clients Manually

Connect to each client (IPs available at `infra/ansible/inventory.ini`)
```zsh
ssh -i infra/keys/key-dsb-us.pem ubuntu@<public_ip_us>
ssh -i infra/keys/key-dsb-us.pem ubuntu@<public_ip_ap>
```

In each machine, schedule the script to run at a given time in the near future
```zsh
cd infra/scripts
date
echo '/home/ubuntu/dsb-mediamicroservices/register.sh > /home/ubuntu/register.log 2>&1' | at 22:27
```

At the end, check the log files (writes in both clients will succeed, but dynamo will contain final converged values, which can be observed in the [AWS console](https://us-east-1.console.aws.amazon.com/dynamodbv2))

```zsh
cat /home/ubuntu/register.log
```

## OPTIONAL: Build Image (only if some modification is done to the application)

Docker (adapt the following commands to use your Docker username and change the image name used for the MovieId service in the `docker-compose.yml` file):

```zsh
cd DeathStarBench/mediaMicroservices
docker build -t mafaldacf/media-microservices .
docker push mafaldacf/media-microservices
```
