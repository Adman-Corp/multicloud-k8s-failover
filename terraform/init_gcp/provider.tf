terraform {
  required_version = ">= 1.0"

  cloud {
    organization = "AdmanCorp"

    workspaces {
      name = "admancorp-gcp-init"
    }
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0"
    }
    tfe = {
      source  = "hashicorp/tfe"
      version = "~> 0.62"
    }
  }
}

provider "google" {
  billing_project = var.bootstrap_project_id
  region          = var.region
}

provider "google-beta" {
  billing_project = var.bootstrap_project_id
  region          = var.region
}

provider "tfe" {
  hostname = var.tfc_hostname
}
