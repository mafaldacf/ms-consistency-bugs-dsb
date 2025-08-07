terraform {
  required_providers {
    aws = {
        source  = "hashicorp/aws"
        version = "~> 5.0"
    }
  }

    required_version = ">= 1.3"
}

module "dynamodb_global_table" {
    source         = "./modules/dynamodb"
    table_name     = "movie-id"
    primary_region = "us-east-1"
    replica_region = "ap-southeast-1"
}

module "ec2_us" {
    source          = "./modules/ec2"
    instance_region = "us-east-1"
    instance_name   = "dsb-us"
    instance_ami    = "ami-020cba7c55df1f615"
}

module "ec2_ap" {
    source          = "./modules/ec2"
    instance_region = "ap-southeast-1"
    instance_name   = "dsb-ap"
    instance_ami    = "ami-02c7683e4ca3ebf58"
}

resource "local_file" "ansible_inventory" {
  filename = "../ansible/inventory.ini"
  content  = <<EOT
[dsb_mediamicroservices]
dsb_us ansible_host=${module.ec2_us.public_ip} ansible_user=ubuntu ansible_ssh_private_key_file=../keys/key-dsb-us.pem
dsb_ap ansible_host=${module.ec2_ap.public_ip} ansible_user=ubuntu ansible_ssh_private_key_file=../keys/key-dsb-ap.pem
EOT
}
