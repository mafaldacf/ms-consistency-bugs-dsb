variable "instance_region" {}
variable "instance_name" {}
variable "instance_ami" {}
variable "instance_type" {}

variable "base_ports_tcp" {
  type    = list(string)
  default = ["22", "80", "443", "8080"]
}

variable "docker_swarm_internal_ports_tcp" {
  type    = list(string)
  default = ["2377", "7946"]
}

variable "docker_swarm_internal_ports_udp" {
  type    = list(string)
  default = ["7946", "4789"]
}

variable "couchdb_external_ports_tcp" {
  type    = list(string)
  default = ["5984"]
}

variable "couchdb_internal_ports_tcp" {
  type    = list(string)
  default = ["5986", "10010", "10011", "10012"]
}

provider "aws" {
  region = var.instance_region
}

data "aws_vpc" "default" {
  default  = true
}

resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = "key-${var.instance_name}"
  public_key = tls_private_key.ssh_key.public_key_openssh
}

resource "local_file" "private_key_pem" {
  content              = tls_private_key.ssh_key.private_key_pem
  filename             = "../keys/key-${var.instance_name}.pem"
  file_permission      = "0600"
  directory_permission = "0700"
}

resource "aws_security_group" "dsb_security_group" {
  name        = "${var.instance_name}-ssh"
  description = "dsb security group"
  vpc_id      = data.aws_vpc.default.id
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.dsb_security_group.id
  description       = "allow all ipv4"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  from_port         = 0
  to_port           = 0
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv6" {
  security_group_id = aws_security_group.dsb_security_group.id
  description       = "allow all ipv6"
  cidr_ipv6         = "::/0"
  ip_protocol       = "-1"
  from_port         = 0
  to_port           = 0
}

resource "aws_security_group_rule" "rule_base_ports_tcp" {
  for_each          = toset(var.base_ports_tcp)
  description       = "base ports tcp"
  security_group_id = aws_security_group.dsb_security_group.id
  type              = "ingress"
  from_port         = each.value
  to_port           = each.value
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "rule_docker_swarm_internal_ports_tcp" {
  for_each          = toset(var.docker_swarm_internal_ports_tcp)
  description       = "docker swarm internal ports tcp"
  security_group_id = aws_security_group.dsb_security_group.id
  type              = "ingress"
  from_port         = each.value
  to_port           = each.value
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "rule_docker_swarm_internal_ports_udp" {
  for_each          = toset(var.docker_swarm_internal_ports_udp)
  description       = "docker swarm internal ports udp"
  security_group_id = aws_security_group.dsb_security_group.id
  type              = "ingress"
  from_port         = each.value
  to_port           = each.value
  protocol          = "udp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "rule_couchdb_external_ports_tcp" {
  for_each          = toset(var.couchdb_external_ports_tcp)
  description       = "couchdb external ports tcp"
  security_group_id = aws_security_group.dsb_security_group.id
  type              = "ingress"
  from_port         = each.value
  to_port           = each.value
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}


resource "aws_security_group_rule" "rule_couchdb_internal_ports_tcp" {
  for_each          = toset(var.couchdb_internal_ports_tcp)
  description       = "couchdb internal ports tcp"
  security_group_id = aws_security_group.dsb_security_group.id
  type              = "ingress"
  from_port         = each.value
  to_port           = each.value
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_instance" "instance" {
  ami                       = var.instance_ami
  instance_type             = var.instance_type
  key_name                  = aws_key_pair.generated_key.key_name
  vpc_security_group_ids    = [aws_security_group.dsb_security_group.id]

  root_block_device {
    volume_size = 50
    volume_type = "gp3"
  }

  tags = {
    Name = var.instance_name
  }

  user_data = <<-EOF
#!/bin/bash
hostnamectl set-hostname ${var.instance_name}
echo "preserve_hostname: true" > /etc/cloud/cloud.cfg.d/99-preserve-hostname.cfg
EOF
}

output "public_ip" {
  value = aws_instance.instance.public_ip
}

output "private_ip" {
  value = aws_instance.instance.private_ip
}
