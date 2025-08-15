terraform {
  required_providers {
    aws = {
        source  = "hashicorp/aws"
        version = "~> 5.0"
    }
  }

    required_version = ">= 1.3"
}

#module "dynamodb_global_table" {
#  source         = "./modules/aws_dynamodb"
#  table_name     = "dsb-movie-id"
#  primary_region = "us-east-1"
#  replica_region = "ap-southeast-1"
#}

module "ec2_manager" {
  source          = "./modules/aws_ec2"
  instance_region = "eu-central-1"
  instance_type   = "t2.small"
  instance_name   = "manager"
  instance_ami    = "ami-02003f9f0fde924ea"
}

module "ec2_node_us" {
  source          = "./modules/aws_ec2"
  instance_region = "us-east-1"
  instance_type   = "t2.large"
  instance_name   = "node-us"
  instance_ami    = "ami-020cba7c55df1f615"
}

module "ec2_node_ap" {
  source          = "./modules/aws_ec2"
  instance_region = "ap-southeast-1"
  instance_type   = "t2.large"
  instance_name   = "node-ap"
  instance_ami    = "ami-02c7683e4ca3ebf58"
}

resource "local_file" "ansible_inventory" {
  filename = "../../ansible/inventory.ini"
  content  = <<EOT
manager ansible_host=${module.ec2_manager.public_ip} swarm_advertise_addr=${module.ec2_manager.public_ip} ansible_ssh_private_key_file=../../tmp/key-manager.pem
node_us ansible_host=${module.ec2_node_us.public_ip} swarm_advertise_addr=${module.ec2_node_us.public_ip} ansible_ssh_private_key_file=../../tmp/key-node-us.pem
node_ap ansible_host=${module.ec2_node_ap.public_ip} swarm_advertise_addr=${module.ec2_node_ap.public_ip} ansible_ssh_private_key_file=../../tmp/key-node-ap.pem

[swarm_nodes]
manager
node_us
node_ap

[swarm_workers]
node_us
node_ap

[dsb_mediamicroservices]
node_us
node_ap

[all:vars]
ansible_user=ubuntu
EOT
}

resource "local_file" "cluster_hosts" {
  filename = "${path.module}/../../tmp/hosts"
  content  = <<EOT
NODE_01_HOST=${module.ec2_node_us.public_ip}
NODE_02_HOST=${module.ec2_node_ap.public_ip}
EOT
}

resource "local_file" "ssh_node_manager" {
  filename = "${path.module}/../../ssh_node.sh"
  content  = <<EOT
#!/bin/bash
set -e

case "$1" in
  manager)
    ssh -i tmp/key-manager.pem ubuntu@${module.ec2_manager.public_ip}
    ;;
  us)
    ssh -i tmp/key-node-us.pem ubuntu@${module.ec2_node_us.public_ip}
    ;;
  ap)
    ssh -i tmp/key-node-ap.pem ubuntu@${module.ec2_node_ap.public_ip}
    ;;
  *)
    echo "Usage: \$0 {manager|us|ap}"
    exit 1
    ;;
esac
EOT
}
