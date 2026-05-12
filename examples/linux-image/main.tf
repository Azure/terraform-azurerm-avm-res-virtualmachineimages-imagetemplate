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
  version = "0.3.0"
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
      runOutputName = "ubuntuManagedImage"
      location      = azurerm_resource_group.this.location
      artifactTags = {
        environment = "demo"
        os          = "linux"
      }
      imageId = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example-rg/providers/Microsoft.Compute/images/example-ubuntu-image"
    }
  ]
  location  = azurerm_resource_group.this.location
  name      = "ubuntu-image-template"
  parent_id = azurerm_resource_group.this.id
  source_image = {
    type      = "PlatformImage"
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
  customize = [
    {
      type = "Shell"
      name = "UpdateSystem"
      inline = [
        "sudo apt-get update",
        "sudo apt-get upgrade -y"
      ]
    },
    {
      type = "Shell"
      name = "InstallTools"
      inline = [
        "sudo apt-get install -y curl wget git vim htop"
      ]
    },
    {
      type = "Shell"
      name = "InstallDocker"
      inline = [
        "curl -fsSL https://get.docker.com -o get-docker.sh",
        "sudo sh get-docker.sh",
        "sudo usermod -aG docker $USER"
      ]
    }
  ]
  enable_telemetry = var.enable_telemetry
  identity = {
    type                       = "UserAssigned"
    user_assigned_resource_ids = [azurerm_user_assigned_identity.this.id]
  }
  tags = {
    environment = "demo"
    os          = "linux"
  }
}
