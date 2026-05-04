terraform {
  required_version = ">= 1.0"

  cloud {
    organization = "AdmanCorp"

    workspaces {
      name = "admancorp-azure-init"
    }
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.12"
    }
    tfe = {
      source  = "hashicorp/tfe"
      version = "~> 0.62"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "azuread" {}

provider "tfe" {
  hostname = var.tfc_hostname
}
