resource "hcloud_ssh_key" "me" {
  name       = "windhelm-root"
  public_key = file(var.ssh_public_key_path)
}

resource "hcloud_server" "main" {
  name               = "windhelm"
  server_type        = "cx23"
  location           = "nbg1"
  image              = "ubuntu-26.04"
  backups            = false
  delete_protection  = true
  rebuild_protection = true

  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [image, ssh_keys, user_data]
  }
}