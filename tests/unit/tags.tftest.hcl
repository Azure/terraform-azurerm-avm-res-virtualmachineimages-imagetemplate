mock_provider "azapi" {}
mock_provider "azurerm" {}
mock_provider "modtm" {}
mock_provider "random" {}

variables {
  distribute = [{
    type          = "ManagedImage"
    runOutputName = "unitImage"
    location      = "westeurope"
    imageId       = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit/providers/Microsoft.Compute/images/unit-image"
  }]
  location  = "westeurope"
  name      = "unit-image-template"
  parent_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit"
  source_image = {
    type      = "PlatformImage"
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
  enable_telemetry = false
  identity = {
    type                       = "UserAssigned"
    user_assigned_resource_ids = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit/providers/Microsoft.ManagedIdentity/userAssignedIdentities/unit-identity"]
  }
}

run "omitted_tags_use_the_nullable_default" {
  command = plan

  assert {
    condition     = var.tags == null
    error_message = "Omitted tags must retain the standard nullable input default."
  }
}

run "null_tags_are_accepted" {
  command = plan

  variables {
    tags = null
  }

  assert {
    condition     = var.tags == null
    error_message = "An explicit null must remain a valid tag input."
  }
}

run "empty_tags_are_preserved" {
  command = plan

  variables {
    tags = {}
  }

  assert {
    condition     = length(azapi_resource.image_template.tags) == 0
    error_message = "An explicit empty tag map must stay empty."
  }
}

run "custom_tags_are_preserved" {
  command = plan

  variables {
    tags = {
      environment = "unit"
      owner       = "ci"
    }
  }

  assert {
    condition     = azapi_resource.image_template.tags == var.tags
    error_message = "All supplied tags must reach the resource without additions or replacements."
  }
}
