# CLAUDE.md

## Purpose
This is a learning project. I'm learning DevOps, Terraform, Ansible, Kubernetes, and CI/CD
by managing a single Hetzner Cloud VPS entirely as code. Explain the *why* behind
changes, point out industry best practices, and push back if I'm doing something wrong.
Prefer teaching over silently doing.

## Architecture (layers)
1. **Terraform** (`infra/terraform/`): Hetzner resources: server, firewall, SSH keys, later volumes, DNS, S3 buckets.
2. **Ansible** (`infra/ansible/`): OS hardening (SSH, unattended-upgrades, fail2ban), installs k3s. Must be idempotent.
3. **Flux GitOps** (`infra/clusters/prod/`): everything inside the cluster is declared here; the cluster pulls from git.
4. **Platform**: cert-manager + Let's Encrypt, Traefik (bundled with k3s), SOPS + age for secrets, monitoring (Prometheus/Grafana or VictoriaMetrics), Loki logs, Alertmanager.
5. **Apps**: Forgejo first.
6. **Backups**: Velero or restic to S3-compatible object storage, with restore drills.

CI/CD lives in `.github/workflows/` in this same monorepo, with path filters per layer.

## Current state
- `infra/terraform/`: versions.tf, variables.tf, server.tf, firewall.tf, outputs.tf.
- Server, SSH key (`windhelm-root`) and firewall are **imported and managed by Terraform**; `plan` shows no changes. State is local for now (gitignored); later moving to an S3 backend.
- Firewall: SSH (22) only from `admin_ips`; 80/443/ICMP public.
- OS is Ubuntu 26.04 LTS (rebuilt in place via `hcloud server rebuild`, outside Terraform).
- `infra/ansible/`: dynamic hcloud inventory (needs `HCLOUD_TOKEN`), `playbooks/hardening.yml`, collections pinned in requirements.yml.
  Applied: users `rafael` (human, sudo with password) and `deploy` (automation, key-only, NOPASSWD sudo);
  root SSH and password auth disabled; unattended-upgrades; fail2ban with `ignoreip` from `TF_VAR_admin_ips`.
  Run with `ansible-playbook playbooks/hardening.yml` (defaults to the `deploy` user).
- Next: k3s, the second half of roadmap step 3.

## Hard rules
- **The server must never be destroyed or replaced.** It's on a legacy price I want to keep. It has
  `prevent_destroy`, `delete_protection`, `rebuild_protection`, and `ignore_changes = [image, ssh_keys, user_data]`.
  Never remove these. For a rebuild, rebuild protection is disabled temporarily via `hcloud` and restored by the next `apply`. If any change would cause `forces replacement`, stop and tell me.
- `image`, `ssh_keys`, and `user_data` on `hcloud_server` force replacement, so SSH keys on the host are managed by Ansible, not Terraform.
- **This is a PUBLIC repo.** Never commit secrets, tokens, state files, `.tfvars`, private keys, or my IP address. Secrets go in env vars, GitHub Actions secrets, or SOPS-encrypted files.
- `HCLOUD_TOKEN` and `TF_VAR_admin_ips` come from the environment only.
- The k8s API (6443) must never be publicly exposed.
- **Do not run `terraform`, `hcloud`, or `ansible` commands yourself** (not even `fmt`, `validate`, or `plan`). I run everything myself so I can see and learn from the output. Give me the exact command, explain why, and tell me what to look for in the output.

## Roadmap
1. Terraform import + firewall, then clean OS rebuild
2. Remote state backend (Hetzner Object Storage, S3 backend)
3. Ansible: hardening + k3s
4. GitHub Actions: fmt/validate/plan on PR, plan as PR comment, gitleaks, tflint, ansible-lint
5. Flux bootstrap + SOPS + cert-manager + Forgejo
6. Monitoring, logging, alerting, plus an **external** uptime check
7. Backups + restore test
8. Later: Renovate, ephemeral test env (spin up throwaway VM, test, destroy), second node

## Conventions
- Terraform: one file per concern, pinned provider versions, commit `.terraform.lock.hcl`, run `terraform fmt` before committing.
- Small, focused commits with conventional commit messages (`feat:`, `fix:`, `chore:`).
- When suggesting something new, tell me which roadmap step it belongs to.
