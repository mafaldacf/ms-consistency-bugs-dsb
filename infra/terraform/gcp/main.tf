provider "google" {
  project     = var.project_id
  region      = "europe-west1"
  zone        = "europe-west1-b"
  credentials = file(var.credentials_file)
}

resource "google_compute_firewall" "allow_base_ports" {
  name    = "allow-base-ports"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "443", "8080"]
  }

  allow {
    protocol = "udp"
    ports    = ["7946", "4789"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags = ["mediamicroservices"]
}

resource "google_compute_firewall" "allow_database_ports" {
  name    = "allow-database-ports"
  network = "default"

  allow {
    protocol = "tcp"
    # 1001X -> couchdb
    # 1002X -> postgresql
    # 1003X -> scylladb
    ports    = ["10010", "10011", "10020", "10021", "10022", "10030", "10031", "10032", "10033", "10034", "10035"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["datastores"]
}

resource "google_compute_firewall" "allow_swarm_internal" {
  name    = "allow-swarm-internal"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["2377", "7946"]
  }

  allow {
    protocol = "udp"
    ports    = ["7946", "4789"]
  }

  source_tags = ["swarm"]
  target_tags = ["swarm"]
}

resource "google_compute_firewall" "allow_couchdb_ports" {
  name    = "allow-couchdb"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["5984", "5986"]
  }

  source_tags = ["datastores"]
  target_tags = ["datastores"]
}

resource "google_compute_firewall" "allow_postgres_ports" {
  name    = "allow-postgresql"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["5432"]
  }

  source_tags = ["datastores"]
  target_tags = ["datastores"]
}

resource "google_compute_firewall" "allow_scylladb_ports" {
  name    = "allow-scylladb"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["7000", "7001", "7199", "9042", "9100", "9142", "9160", "9180", "10000", "19042", "19142"]
  }

  source_tags = ["datastores"]
  target_tags = ["datastores"]
}

resource "google_compute_instance" "manager" {
  name         = "manager"
  machine_type = "e2-medium"
  zone         = "europe-west1-b"
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = 50
    }
  }
  network_interface {
    network = "default"
    access_config {}
  }

  tags = ["mediamicroservices", "datastores", "swarm"]

  metadata = {
    ssh-keys = "${var.gcp_user}:${file("~/.ssh/google_compute_engine.pub")}"
  }
}

resource "google_compute_instance" "node_us" {
  name         = "node-us"
  machine_type = "e2-medium"
  zone         = "us-central1-a"
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = 50
    }
  }
  network_interface {
    network = "default"
    access_config {}
  }

  tags = ["mediamicroservices", "datastores", "swarm"]

  metadata = {
    ssh-keys = "${var.gcp_user}:${file("~/.ssh/google_compute_engine.pub")}"
  }
}

resource "google_compute_instance" "node_ap" {
  name         = "node-ap"
  machine_type = "e2-medium"
  zone         = "asia-southeast1-a"
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = 50
    }
  }
  network_interface {
    network = "default"
    access_config {}
  }

  tags = ["mediamicroservices", "datastores", "swarm"]

  metadata = {
    ssh-keys = "${var.gcp_user}:${file("~/.ssh/google_compute_engine.pub")}"
  }
}

locals {
  manager_public_ip   = google_compute_instance.manager.network_interface[0].access_config[0].nat_ip
  manager_internal_ip = google_compute_instance.manager.network_interface[0].network_ip

  node_us_public_ip   = google_compute_instance.node_us.network_interface[0].access_config[0].nat_ip
  node_us_internal_ip = google_compute_instance.node_us.network_interface[0].network_ip

  node_ap_public_ip   = google_compute_instance.node_ap.network_interface[0].access_config[0].nat_ip
  node_ap_internal_ip = google_compute_instance.node_ap.network_interface[0].network_ip
}

resource "local_file" "ansible_inventory" {
  filename = "../../ansible/inventory.ini"
  content  = <<EOT
manager ansible_host=${local.manager_public_ip} swarm_advertise_addr=${local.manager_internal_ip} ansible_ssh_private_key_file=~/.ssh/google_compute_engine
node_us ansible_host=${local.node_us_public_ip} swarm_advertise_addr=${local.node_us_internal_ip} ansible_ssh_private_key_file=~/.ssh/google_compute_engine
node_ap ansible_host=${local.node_ap_public_ip} swarm_advertise_addr=${local.node_ap_internal_ip} ansible_ssh_private_key_file=~/.ssh/google_compute_engine

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
ansible_user=${var.gcp_user}
project_id=${var.project_id}
EOT
}

resource "local_file" "cluster_hosts" {
  filename = "${path.module}/../../tmp/hosts"
  content  = <<EOT
MANAGER_HOST=${local.manager_public_ip}
NODE_01_HOST=${local.node_us_public_ip}
NODE_02_HOST=${local.node_ap_public_ip}
EOT
}

resource "local_file" "ssh_node_manager" {
  filename = "${path.module}/../../ssh_node.sh"
  content  = <<EOT
#!/bin/bash
set -e

case "$1" in
  manager)
    # gcloud compute ssh --zone "europe-west1-b" "manager" --project "${var.project_id}"
    ssh -i ~/.ssh/google_compute_engine ${var.gcp_user}@${local.manager_public_ip}
    ;;
  us)
    # gcloud compute ssh --zone "us-central1-a" "node_us" --project "${var.project_id}"
    ssh -i ~/.ssh/google_compute_engine ${var.gcp_user}@${local.node_us_public_ip}
    ;;
  ap)
    # gcloud compute ssh --zone "asia-southeast1-a" "node_ap" --project "${var.project_id}"
    ssh -i ~/.ssh/google_compute_engine ${var.gcp_user}@${local.node_ap_public_ip}
    ;;
  *)
    echo "Usage: \$0 {manager|us|ap}"
    exit 1
    ;;
esac
EOT
}
