locals {
  image_template_body = merge(
    {
      properties = local.image_template_properties
    },
    local.image_template_identity == null ? {} : {
      identity = local.image_template_identity
    }
  )
  image_template_identity = var.identity == null ? null : merge(
    {
      type = var.identity.type
    },
    length(local.user_assigned_identity_map) == 0 ? {} : {
      userAssignedIdentities = local.user_assigned_identity_map
    }
  )
  image_template_properties = merge(
    {
      source     = var.source_image
      customize  = var.customize
      distribute = var.distribute
    },
    var.build_timeout_in_minutes == null ? {} : {
      buildTimeoutInMinutes = var.build_timeout_in_minutes
    },
    var.staging_resource_group_id == null ? {} : {
      stagingResourceGroupId = var.staging_resource_group_id
    },
    length(local.vm_profile) == 0 ? {} : {
      vmProfile = local.vm_profile
    }
  )
  role_definition_resource_substring = "/providers/Microsoft.Authorization/roleDefinitions"
  user_assigned_identity_map = var.identity == null || var.identity.user_assigned_resource_ids == null ? {} : {
    for id in var.identity.user_assigned_resource_ids : id => {}
  }
  vm_profile = merge(
    var.vm_profile_overrides,
    var.vm_size == null ? {} : {
      vmSize = var.vm_size
    }
  )
}
