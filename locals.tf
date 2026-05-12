locals {
  image_template_body = {
    properties = local.image_template_properties
  }
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
  vm_profile = merge(
    var.vm_profile_overrides,
    var.vm_size == null ? {} : {
      vmSize = var.vm_size
    }
  )
}
