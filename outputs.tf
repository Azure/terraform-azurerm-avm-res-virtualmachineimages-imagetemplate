output "location" {
  description = "The Azure region where the image template is deployed."
  value       = azapi_resource.image_template.location
}

output "name" {
  description = "The name of the image template resource."
  value       = azapi_resource.image_template.name
}

output "resource" {
  description = "The full image template resource object."
  value       = azapi_resource.image_template
}

output "resource_id" {
  description = "The fully qualified resource ID of the image template."
  value       = azapi_resource.image_template.id
}
