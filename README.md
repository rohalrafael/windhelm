# windhelm

## What

Hetzner CX23 managed as code.

## Why

A learning project for Terraform, Ansible, Kubernetes, and other similarly magical stuff.

## What works today

- Terraform manages the existing server, its SSH key and its firewall.
- Ubuntu 26.04 LTS.
- Ansible applies base hardening: an admin user and a separate automation user, key-only SSH with root login and password auth disabled, unattended-upgrades, and fail2ban.
- Terraform state is local and gitignored. Moving it to object storage is the next infrastructure task. CI (fmt/validate/plan, linting, secret scanning) comes after that.

## Decisions

**Import the server instead of recreating it.** The server predates this repo and sits on a price that would be lost by replacing it (lol yes i am that cheap). It carries `prevent_destroy` in Terraform plus Hetzner's own delete and rebuild protection, and `ignore_changes = [image, ssh_keys, user_data]` because those attributes force replacement. The OS reinstall was therefore done with `hcloud server rebuild`, outside Terraform: same server, same IP, but a fresh OS.

**Two users.** `deploy` is for automation: key-only, no password, passwordless sudo, because Ansible cannot type a password. `rafael` is the human (me) account and its sudo asks for a password, so a stolen key alone is not instant root. The separation does not reduce privilege (both reach root), it makes credentials revocable independently and makes logs say whether a change came from a person or a pipeline.

**This repo is public.** Nothing identifying goes in here. The server address comes from Ansible's dynamic Hetzner inventory at runtime, the admin IP from an environment variable shared with Terraform, and state files, tfvars and keys are gitignored. 

## Running it

Step 1: Don't. Only I, the CEO of this server, can do this.

```sh
# infrastructure
cd infra/terraform && terraform init && terraform plan

# host configuration
cd infra/ansible
ansible-galaxy collection install -r requirements.yml
ansible-playbook playbooks/hardening.yml
```

Both Terraform and Ansible need `HCLOUD_TOKEN` in the environment. Terraform and fail2ban also need `TF_VAR_admin_ips`. The playbook is idempotent: a second run should report no changes.