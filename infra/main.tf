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
  name    = "admin-ssh"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [var.pierre_ip]
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
