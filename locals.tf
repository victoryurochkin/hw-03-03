locals {
  ssh_public_key = file(pathexpand("~/.ssh/id_rsa.pub"))

  vm_metadata = {
    ssh-keys = "${var.vm_ssh_user}:${local.ssh_public_key}"
  }

  web_vm_names = [
    for index in range(var.web_vm_count) : "${var.web_vm_name_prefix}-${index + 1}"
  ]
}
