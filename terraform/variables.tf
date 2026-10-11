variable "project_name" {
  description = "Prefix for cloud resources."
  type        = string
  default     = "devops-foundation"
}

variable "external_network_id" {
  description = "ID of the provider external network used by the router."
  type        = string
}

variable "image_name" {
  description = "Ubuntu 22.04 image name exposed by the cloud."
  type        = string
  default     = "Ubuntu 22.04"
}

variable "flavor_name" {
  description = "VM flavor appropriate for the lab."
  type        = string
  default     = "m1.small"
}

variable "ssh_public_key_path" {
  description = "Absolute path to the public SSH key used for the student account."
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "Trusted public CIDR allowed to reach SSH."
  type        = string
  validation {
    condition     = can(cidrhost(var.allowed_ssh_cidr, 0)) && var.allowed_ssh_cidr != "0.0.0.0/0"
    error_message = "Use a valid, non-global CIDR for SSH."
  }
}

variable "student_username" {
  description = "Existing Ubuntu image user allowed to log in with the uploaded key."
  type        = string
  default     = "student"
}

variable "manage_iam" {
  description = "Create a project-scoped automation user. Requires Keystone administrator rights."
  type        = bool
  default     = false
}

variable "iam_domain_id" {
  description = "Keystone domain containing the automation user; needed only when manage_iam is true."
  type        = string
  default     = null
  nullable    = true
}

variable "iam_project_id" {
  description = "Project ID to scope the least-privilege role assignment to."
  type        = string
  default     = null
  nullable    = true
}

variable "vm_operator_role_id" {
  description = "ID of a pre-created role limited to VM lifecycle operations in the target project."
  type        = string
  default     = null
  nullable    = true
}

variable "iam_password" {
  description = "Initial password for the automation user. Pass through TF_VAR_iam_password; never commit it."
  type        = string
  default     = null
  nullable    = true
  sensitive   = true
}
