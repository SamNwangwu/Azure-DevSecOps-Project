terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "tfstate18805"
    container_name       = "tfstate"
    key                  = "azure-devsecops.tfstate"
  }
}

provider "azurerm" {
  features {}
  skip_provider_registration = true
}
