# DevOps infrastructure foundation

Homework #1 for Amir Khusnutdinov (`khusnutdinovar`). The project implements a reproducible Ubuntu host using Terraform, Ansible, Docker Compose and a Bash health-check utility.

## Architecture

```text
Internet -> SSH/22 (trusted CIDR only) -> Ubuntu VM
                                           |- Docker Engine
                                           |- deployer (passwordless sudo, Docker group)
                                           `- Docker Compose: nginx:80 -> app:80
```

Terraform targets an OpenStack-compatible MWS project and creates a network, subnet, router, a VM, a floating IP, a key pair and a least-privilege security group. Cloud credentials are deliberately obtained from `OS_*` environment variables; neither credentials nor state are committed. The VM accepts SSH only from `allowed_ssh_cidr`.

`terraform/iam.tf` additionally defines an opt-in, project-scoped automation user and a role assignment. It is disabled by default because Keystone creates users and assignments only for a cloud administrator. When enabled, `vm_operator_role_id` must be supplied by the provider as a role limited to VM lifecycle actions; do not assign `admin`. The initial password must arrive via `TF_VAR_iam_password`, because user passwords are stored in Terraform state.

> The security-group requirement deliberately permits only SSH. To test `curl http://VM_IP` from outside the VM, an instructor-approved HTTP/80 rule must be added temporarily or the command should run on the VM as `curl http://localhost`.

## Repository layout

| Directory | Purpose |
| --- | --- |
| `terraform` | OpenStack-compatible infrastructure definition |
| `ansible` | Ubuntu Docker setup and deployment of `/opt/app` |
| `scripts` | Shell monitoring utility |
| `evidence` | Local, ignored outputs/screenshots collected during validation |

## Prerequisites

- Terraform >= 1.5 and an OpenStack/MWS project credential set (`OS_AUTH_URL`, `OS_USERNAME`, `OS_PASSWORD`, `OS_PROJECT_NAME` or application credentials).
- An SSH key pair and a trusted public source CIDR.
- Ansible and the `community.docker` collection on the control host.

## Provision infrastructure

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit only the REPLACE_* values; do not add a real tfvars file to Git.
terraform init
terraform fmt -check
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
terraform state list
```

The generated floating IP is printed as `vm_public_ip`. If an instructor supplies an existing VM instead, use its IP in the Ansible inventory; Terraform remains the reproducible definition for a fresh lab environment.

## Configure host and deploy application

```bash
ansible-galaxy collection install -r ansible/requirements.yml
cp ansible/inventory.ini.example ansible/inventory.ini
# Confirm the host IP and SSH username in inventory.ini.
ansible-playbook -i ansible/inventory.ini ansible/setup_host.yml --ask-become-pass
ansible-playbook -i ansible/inventory.ini ansible/setup_host.yml --ask-become-pass
```

The second run must finish with `changed=0`. The playbook is idempotent: packages converge to `present`, users/directories/files use their desired state, and Compose is started only when its project files changed.

On the VM, verify the stack:

```bash
sudo -u deployer docker compose -f /opt/app/docker-compose.yml ps
curl -fsS http://localhost
```

The externally reachable `nginx` service listens on port 80 and reverse-proxies to the private `app` service over the `app_net` bridge network. The app container has no published host port.

## Monitoring utility

```bash
chmod +x scripts/monitor.sh
sudo scripts/monitor.sh docker
sudo scripts/monitor.sh nonexistent.service  # expected: exit code 4
```

The script validates its service argument, calls `systemctl is-active`, prints ten journal lines when the unit is inactive, and uses `grep` plus `awk` to count error-level messages from the last hour in `/var/log/syslog`. A missing syslog is reported explicitly rather than hidden.

## Evidence for submission

Run the following only against the real lab resources and save terminal output or screenshots under `evidence` locally (the directory is ignored to prevent accidental publication of IP addresses or logs):

```bash
terraform -chdir=terraform state list
ansible-playbook -i ansible/inventory.ini ansible/setup_host.yml --ask-become-pass
ssh student@VM_IP 'sudo -u deployer docker compose -f /opt/app/docker-compose.yml ps; curl -fsS http://localhost; sudo /opt/app/monitor.sh docker'
```

Do not fabricate evidence: as of project preparation, the supplied host did not complete an SSH handshake, so there is no claimed deployment output in this repository.

## Design decisions and troubleshooting

- SSH ingress is narrowed to a single CIDR and Terraform rejects `0.0.0.0/0`; access is by uploaded key, not root login.
- Terraform is declarative: it compares desired resources with `terraform.tfstate`. Removing state does not delete resources, but makes Terraform forget ownership and risks duplicate resources on the next apply.
- Ansible is imperative in syntax but idempotent in modules: each task describes an end state and subsequent runs converge without changes.
- The Compose proxy/app split models a multi-service deployment without exposing the backend. Use `journalctl -u docker -n 10`, `docker logs devops-proxy`, and `curl -v http://localhost` to diagnose failures.

## Git workflow

Work is prepared on `feature/infra-setup`. Before submitting, push it to the course remote, create a Merge Request into `main`, review it, merge it, then run:

```bash
git tag -a v0.1.0 -m 'DevOps infrastructure foundation'
git push origin main --tags
```
