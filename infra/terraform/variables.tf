variable "admin_ips" {
  type        = list(string)
  description = "IPs allowed to SSH, e.g. [\"1.2.3.4/32\"]"
}

variable "ssh_public_key_path" {
  type    = string
  default = "~/.ssh/windhelm_root.pub"
}
