output "nginx_url" {
  description = "URL that must return HTTP 200 from the Terraform-managed nginx container."
  value       = "http://127.0.0.1:${var.external_port}"
}

output "container_name" {
  description = "Name of the Terraform-managed nginx container."
  value       = docker_container.nginx.name
}

output "network_name" {
  description = "Dedicated bridge network for the Terraform-managed nginx container."
  value       = docker_network.nginx.name
}

output "volume_name" {
  description = "Named volume mounted at nginx's web root."
  value       = docker_volume.nginx_html.name
}
