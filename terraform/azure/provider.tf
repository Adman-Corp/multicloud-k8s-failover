terraform {
  required_version = ">= 1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

  cloud {
    organization = "AdmanCorp"
  }
}

provider "azurerm" {
  features {}
}

provider "azuread" {
  # Authentication via environment variables:
  # AZURE_CLIENT_ID, AZURE_CLIENT_SECRET, AZURE_TENANT_ID
  # or via Azure CLI (az login)
}

provider "random" {
  # No configuration needed
}

provider "tls" {
  # No configuration needed
}
