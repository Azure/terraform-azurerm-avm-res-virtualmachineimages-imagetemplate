terraform {
  required_version = ">= 1.5.0, < 2.0.0"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.4"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    modtm = {
      source  = "azure/modtm"
      version = "~> 0.3"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "azurerm" {
  features {}
}

# tflint-ignore: terraform_unused_required_providers
provider "azapi" {}

# tflint-ignore: terraform_unused_required_providers
provider "modtm" {}

module "regions" {
  source  = "Azure/avm-utl-regions/azurerm"
  version = "0.9.0"
}

resource "random_integer" "region_index" {
  max = length(module.regions.regions) - 1
  min = 0
}

module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.3.0"
}

resource "azurerm_resource_group" "this" {
  location = module.regions.regions[random_integer.region_index.result].name
  name     = module.naming.resource_group.name_unique
}

module "image_template" {
  source = "../../"

  distribute = [
    {
      type          = "ManagedImage"
      runOutputName = "customWindowsManagedImage"
      location      = azurerm_resource_group.this.location
      artifactTags = {
        environment = "custom"
      }
      imageId = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example-rg/providers/Microsoft.Compute/images/example-custom-windows-image"
    }
  ]
  location  = azurerm_resource_group.this.location
  name      = "win11-image-template-ignore"
  parent_id = azurerm_resource_group.this.id
  source_image = {
    type      = "PlatformImage"
    publisher = "MicrosoftWindowsDesktop"
    offer     = "windows-11"
    sku       = "win11-23h2-ent"
    version   = "latest"
  }
  customize = [
    {
      type = "PowerShell"
      name = "InstallPackages"
      inline = [
        "Write-Output 'Running custom package install script'"
      ]
    }
  ]
  enable_telemetry = var.enable_telemetry
  identity = {
    type = "SystemAssigned"
  }
  tags = {
    environment = "custom"
  }
}
