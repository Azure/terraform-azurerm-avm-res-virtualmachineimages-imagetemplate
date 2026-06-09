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

  is_recommended = true
  region_filter = [
    "eastus",
    "eastus2",
    "centralus",
    "westcentralus",
    "westus",
    "westus2",
    "southcentralus",
    "westus3",
    "canadacentral",
    "northeurope",
    "westeurope",
    "japaneast",
    "southafricanorth",
    "jioindiawest",
    "eastasia",
    "southeastasia",
    "norwayeast",
    "uksouth",
    "ukwest",
    "uaenorth",
    "germanywestcentral",
    "australiaeast",
    "australiasoutheast",
    "switzerlandnorth",
    "centralindia",
    "francecentral",
    "koreacentral",
    "northcentralus",
    "brazilsouth",
    "qatarcentral",
    "polandcentral",
    "swedencentral",
    "italynorth",
    "israelcentral",
    "spaincentral",
    "jioindiacentral",
    "mexicocentral",
    "newzealandnorth",
    "indonesiacentral",
    "chilecentral",
    "malaysiawest",
    "austriaeast"
  ]
}

resource "random_integer" "region_index" {
  max = length(module.regions.regions) - 1
  min = 0
}

module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.4.3"
}

resource "azurerm_resource_group" "this" {
  location = module.regions.regions[random_integer.region_index.result].name
  name     = module.naming.resource_group.name_unique
}

resource "azurerm_user_assigned_identity" "this" {
  location            = azurerm_resource_group.this.location
  name                = "${module.naming.user_assigned_identity.name_unique}-imagebuilder"
  resource_group_name = azurerm_resource_group.this.name
}

module "image_template" {
  source = "../../"

  distribute = [
    {
      type          = "ManagedImage"
      runOutputName = "windowsManagedImage"
      location      = azurerm_resource_group.this.location
      artifactTags = {
        environment = "demo"
      }
      imageId = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example-rg/providers/Microsoft.Compute/images/example-windows-image"
    }
  ]
  location  = azurerm_resource_group.this.location
  name      = "win11-image-template"
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
      name = "ConfigureWinUpdates"
      inline = [
        "Write-Output 'Configuring Windows Update settings'"
      ]
      runElevated = true
      runAsSystem = true
    }
  ]
  enable_telemetry = var.enable_telemetry
  identity = {
    type                       = "UserAssigned"
    user_assigned_resource_ids = [azurerm_user_assigned_identity.this.id]
  }
  tags = {
    environment = "demo"
  }
}
