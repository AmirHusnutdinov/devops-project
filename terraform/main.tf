data "openstack_images_image_v2" "ubuntu" {
  name        = var.image_name
  most_recent = true
}

resource "openstack_networking_network_v2" "vpc" {
  name           = "${var.project_name}-network"
  admin_state_up = true
}

resource "openstack_networking_subnet_v2" "subnet" {
  name            = "${var.project_name}-subnet"
  network_id      = openstack_networking_network_v2.vpc.id
  cidr            = "10.42.0.0/24"
  ip_version      = 4
  enable_dhcp     = true
  dns_nameservers = ["1.1.1.1", "8.8.8.8"]
}

resource "openstack_networking_router_v2" "router" {
  name                = "${var.project_name}-router"
  admin_state_up      = true
  external_network_id = var.external_network_id
}

resource "openstack_networking_router_interface_v2" "subnet" {
  router_id = openstack_networking_router_v2.router.id
  subnet_id = openstack_networking_subnet_v2.subnet.id
}

resource "openstack_compute_keypair_v2" "student" {
  name       = "${var.project_name}-student"
  public_key = file(var.ssh_public_key_path)
}

resource "openstack_networking_secgroup_v2" "vm" {
  name        = "${var.project_name}-ssh-only"
  description = "Least-privilege ingress: SSH from the student's CIDR only"
}

resource "openstack_networking_secgroup_rule_v2" "ssh_ingress" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = var.allowed_ssh_cidr
  security_group_id = openstack_networking_secgroup_v2.vm.id
}

resource "openstack_compute_instance_v2" "devops_host" {
  name            = "${var.project_name}-vm"
  image_id        = data.openstack_images_image_v2.ubuntu.id
  flavor_name     = var.flavor_name
  key_pair        = openstack_compute_keypair_v2.student.name
  security_groups = [openstack_networking_secgroup_v2.vm.name]
  network {
    uuid = openstack_networking_network_v2.vpc.id
  }
  depends_on = [openstack_networking_router_interface_v2.subnet]
}

resource "openstack_networking_floatingip_v2" "vm" {
  pool = var.external_network_id
}

resource "openstack_compute_floatingip_associate_v2" "vm" {
  floating_ip = openstack_networking_floatingip_v2.vm.address
  instance_id = openstack_compute_instance_v2.devops_host.id
}
