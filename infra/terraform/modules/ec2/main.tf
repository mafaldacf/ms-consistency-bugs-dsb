variable "instance_region" {}
variable "instance_name" {}
variable "instance_ami" {}

provider "aws" {
  alias  = "ec2"
  region = var.instance_region
}

resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  provider   = aws.ec2
  key_name   = "key-${var.instance_name}"
  public_key = tls_private_key.ssh_key.public_key_openssh
}

resource "local_file" "private_key_pem" {
  content              = tls_private_key.ssh_key.private_key_pem
  filename             = "../keys/key-${var.instance_name}.pem"
  file_permission      = "0600"
  directory_permission = "0700"
}

data "aws_vpc" "default" {
  provider = aws.ec2
  default  = true
}

resource "aws_security_group" "ssh" {
  provider    = aws.ec2
  name        = "${var.instance_name}-ssh"
  description = "Allow SSH access"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "instance" {
  provider                  = aws.ec2
  ami                       = var.instance_ami
  instance_type             = "t2.large"
  key_name                  = aws_key_pair.generated_key.key_name
  vpc_security_group_ids    = [aws_security_group.ssh.id]

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  tags = {
    Name = var.instance_name
  }
}

output "public_ip" {
  value = aws_instance.instance.public_ip
}
