# This file defines the providers used in the Terraform configuration for the development environment.
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0"
    }
    random = {
        source  = "hashicorp/random"
        version = ">= 3.0"
    }
  }
  # Backend configuration for storing Terraform state in Azure Blob Storage
  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "dbrelabtfstate"
    container_name       = "tfstate"
    key                  = "sql-mi-dev.tfstate"
  }
}

provider "azurerm" {
  features {
    # This block is mandatory for the AzureRM provider.
    # It allows you to customize behaviors like "delete OS disk on VM termination"
    # but for now, we leave it empty.
  }
}

provider "random" {
  # The random provider doesn't require a features block, 
  # but defining it explicitly is good practice.
}