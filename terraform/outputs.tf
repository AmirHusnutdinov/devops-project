output "vm_public_ip" {
  description = "Public address to put into Ansible inventory."
  value       = openstack_networking_floatingip_v2.vm.address
}

output "ssh_command" {
  description = "Connection command; private key path is intentionally not managed by Terraform."
  value       = "ssh ${var.student_username}@${openstack_networking_floatingip_v2.vm.address}"
}
