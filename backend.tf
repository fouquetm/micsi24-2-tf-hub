terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.7.0"
    }
  }

  backend "local" {
  }
}

provider "azurerm" {
  subscription_id = "10ce0944-5960-42ed-8657-1a8177030014" # peut être remplacé par $env:ARM_SUBSCRIPTION_ID = "10ce0944-5960-42ed-8657-1a8177030014"
  features {}
}
