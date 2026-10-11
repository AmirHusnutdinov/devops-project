# Keystone user and role management is opt-in because it needs cloud-admin rights.
# The role ID must refer to an administrator-approved role with VM-only permissions.
resource "openstack_identity_user_v3" "automation" {
  count = var.manage_iam ? 1 : 0

  name               = "${var.project_name}-automation"
  description        = "Automation identity limited to ${var.project_name} VM operations"
  domain_id          = var.iam_domain_id
  default_project_id = var.iam_project_id
  password           = var.iam_password
  enabled            = true
}

resource "openstack_identity_role_assignment_v3" "automation" {
  count = var.manage_iam ? 1 : 0

  user_id    = openstack_identity_user_v3.automation[0].id
  project_id = var.iam_project_id
  role_id    = var.vm_operator_role_id
}
