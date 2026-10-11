variable "docker_host" {
  description = "Docker daemon endpoint. The default uses the local Unix socket."
  type        = string
  default     = "unix:///var/run/docker.sock"
}

variable "project_name" {
  description = "Prefix for Terraform-managed Docker resources."
  type        = string
  default     = "khusnutdinovar-devops"
}

variable "nginx_image" {
  description = "Nginx image to run."
  type        = string
  default     = "nginx:1.27-alpine"
}

variable "external_port" {
  description = "Non-standard host TCP port that publishes container port 80."
  type        = number
  default     = 8081

  validation {
    condition     = var.external_port >= 1024 && var.external_port <= 65535
    error_message = "external_port must be an unprivileged TCP port between 1024 and 65535."
  }
}
