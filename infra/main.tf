terraform {
  cloud {
    organization = "websokek"

    workspaces {
      name = "websokek"
    }
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.76.0"
    }
  }
}

provider "google" {
  credentials = var.gcp_credentials

  project = var.gcp_project
  region  = var.gcp_region
  zone    = var.gcp_zone
}

resource "google_compute_network" "vpc_network" {
  name = "websokek-network"
}

resource "google_compute_firewall" "firewall" {
  name    = "ping-ssh"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = [var.pierre_ip, var.alex_ip]
  target_tags   = ["server"]
}

resource "google_compute_firewall" "sshall" {
  name    = "sshall"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]

}

resource "google_compute_firewall" "quic" {
  name    = "quic"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "udp"
    ports    = ["443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["server"]
}

resource "google_compute_instance" "vm_instance" {
  name         = "server-paris"
  machine_type = "e2-micro"
  tags         = ["server"]

  boot_disk {
    initialize_params {
      image = "projects/cos-cloud/global/images/cos-101-17162-210-60"
    }
  }

  network_interface {
    network = google_compute_network.vpc_network.name
    access_config {
    }
  }
}
