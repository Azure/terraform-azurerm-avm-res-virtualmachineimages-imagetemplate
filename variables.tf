variable "distribute" {
  type        = list(any)
  description = "Distribution targets for the built image. Must contain at least one entry."
  nullable    = false

  validation {
    condition     = length(var.distribute) > 0
    error_message = "At least one distribution target must be specified."
  }
}

variable "location" {
  type        = string
  description = "Azure region where the image template will be deployed."
  nullable    = false
}

variable "name" {
  type        = string
  description = "Name of the Azure Image Builder template."
  nullable    = false

  validation {
    condition     = can(regex("^[A-Za-z0-9-_]{1,80}$", var.name))
    error_message = "The name must be 1-80 characters and may include letters, numbers, hyphens, or underscores."
  }
}

variable "parent_id" {
  type        = string
  description = "Resource ID of the parent resource (typically the resource group) that will contain the image template."
  nullable    = false

  validation {
    condition     = can(regex("^/subscriptions/[0-9a-fA-F-]+/resourceGroups/[A-Za-z0-9._()-]+$", var.parent_id))
    error_message = "The parent_id must be a valid resource group ID in the format /subscriptions/{guid}/resourceGroups/{name}."
  }
}

variable "source_image" {
  type        = any
  description = "Source configuration for the image template. Refer to Azure Image Builder documentation for supported fields."
  nullable    = false
}

variable "build_timeout_in_minutes" {
  type        = number
  default     = 240
  description = "Timeout for the image build in minutes."
  nullable    = false

  validation {
    condition     = var.build_timeout_in_minutes >= 30 && var.build_timeout_in_minutes <= 960
    error_message = "build_timeout_in_minutes must be between 30 and 960 minutes."
  }
}

variable "customize" {
  type        = list(any)
  default     = []
  description = "List of customization steps to apply during image build."
  nullable    = false
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
  nullable    = false
}

variable "identity" {
  type = object({
    type                       = string
    user_assigned_resource_ids = optional(set(string), null)
  })
  default     = null
  description = "Managed identity configuration for the image template. Only UserAssigned identity type is supported for Image Builder."

  validation {
    condition     = var.identity == null ? true : var.identity.type == "UserAssigned"
    error_message = "Identity type must be UserAssigned. Image Builder does not support SystemAssigned identities."
  }
}

variable "lock" {
  type = object({
    kind = string
    name = optional(string, null)
  })
  default     = null
  description = <<DESCRIPTION
Controls the Resource Lock configuration for this resource. The following properties can be specified:

- `kind` - (Required) The type of lock. Possible values are `"CanNotDelete"` and `"ReadOnly"`.
- `name` - (Optional) The name of the lock. If not specified, a name will be generated based on the `kind` value. Changing this forces the creation of a new resource.
DESCRIPTION

  validation {
    condition     = var.lock != null ? contains(["CanNotDelete", "ReadOnly"], var.lock.kind) : true
    error_message = "The lock level must be one of: 'CanNotDelete' or 'ReadOnly'."
  }
}

variable "role_assignments" {
  type = map(object({
    role_definition_id_or_name             = string
    principal_id                           = string
    description                            = optional(string, null)
    skip_service_principal_aad_check       = optional(bool, false)
    condition                              = optional(string, null)
    condition_version                      = optional(string, null)
    delegated_managed_identity_resource_id = optional(string, null)
    principal_type                         = optional(string, null)
  }))
  default     = {}
  description = <<DESCRIPTION
A map of role assignments to create on this resource. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

- `role_definition_id_or_name` - The ID or name of the role definition to assign to the principal.
- `principal_id` - The ID of the principal to assign the role to.
- `description` - The description of the role assignment.
- `skip_service_principal_aad_check` - If set to true, skips the Azure Active Directory check for the service principal in the tenant. Defaults to false.
- `condition` - The condition which will be used to scope the role assignment.
- `condition_version` - The version of the condition syntax. Valid values are '2.0'.
- `delegated_managed_identity_resource_id` - The delegated Azure Resource Id which contains a Managed Identity. Changing this forces a new resource to be created.
- `principal_type` - The type of the principal_id. Possible values are `User`, `Group` and `ServicePrincipal`. Changing this forces a new resource to be created. It is necessary to explicitly set this attribute when creating role assignments if the principal creating the assignment is constrained by ABAC rules that filters on the PrincipalType attribute.

> Note: only set `skip_service_principal_aad_check` to true if you are assigning a role to a service principal.
DESCRIPTION
  nullable    = false
}

variable "staging_resource_group_id" {
  type        = string
  default     = null
  description = "Optional resource ID of a staging resource group for the image builder template."
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "Tags to associate with the image template."
}

variable "vm_profile_overrides" {
  type        = map(any)
  default     = {}
  description = "Additional VM profile properties to merge with the defaults when building the image."
  nullable    = false
}

variable "vm_size" {
  type        = string
  default     = "Standard_D2s_v3"
  description = "VM size used during image build."
  nullable    = false
}
