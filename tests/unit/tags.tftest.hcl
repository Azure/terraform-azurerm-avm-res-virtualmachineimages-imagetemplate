mock_provider "azapi" {
  mock_data "azapi_client_config" {
    defaults = {
      subscription_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000"
    }
  }
}
mock_provider "azurerm" {}
mock_provider "terraform" {}

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

run "disabled_telemetry_creates_no_payload" {
  command = plan

  assert {
    condition = (
      length(azapi_resource.telemetry) == 0 &&
      length(terraform_data.telemetry) == 0 &&
      length(data.azapi_client_config.telemetry) == 0
    )
    error_message = "Disabling telemetry must omit the deployment, instance and client lookup."
  }
}

run "enabled_telemetry_uses_an_empty_subscription_deployment" {
  command = plan

  variables {
    enable_telemetry = true
    tags = {
      environment = "unit"
    }
  }

  assert {
    condition = (
      length(azapi_resource.telemetry) == 1 &&
      length(terraform_data.telemetry) == 1 &&
      azapi_resource.telemetry[0].type == "Microsoft.Resources/deployments@2025-04-01" &&
      azapi_resource.telemetry[0].location == var.location &&
      azapi_resource.telemetry[0].parent_id == "/subscriptions/00000000-0000-0000-0000-000000000000" &&
      azapi_resource.telemetry[0].body.properties.mode == "Incremental" &&
      length(azapi_resource.telemetry[0].body.properties.template.resources) == 0
    )
    error_message = "Enabled telemetry must use an empty incremental deployment in the active subscription and requested region."
  }

  assert {
    condition     = azapi_resource.image_template.tags == var.tags
    error_message = "Enabling telemetry must not change the image template's supplied tags."
  }
}
