locals {
  ansible_webservers = [
    for vm in yandex_compute_instance.web : {
      name        = vm.name
      external_ip = vm.network_interface[0].nat_ip_address
      fqdn        = vm.fqdn
    }
  ]

  ansible_databases = [
    for vm_name in sort(keys(yandex_compute_instance.db)) : {
      name        = yandex_compute_instance.db[vm_name].name
      external_ip = yandex_compute_instance.db[vm_name].network_interface[0].nat_ip_address
      fqdn        = yandex_compute_instance.db[vm_name].fqdn
    }
  ]

  ansible_storage = [
    {
      name        = yandex_compute_instance.storage.name
      external_ip = yandex_compute_instance.storage.network_interface[0].nat_ip_address
      fqdn        = yandex_compute_instance.storage.fqdn
    }
  ]
}

resource "local_file" "ansible_inventory" {
  filename = "${path.module}/inventory.ini"

  content = templatefile("${path.module}/templates/inventory.tftpl", {
    webservers = local.ansible_webservers
    databases  = local.ansible_databases
    storage    = local.ansible_storage
  })
}
