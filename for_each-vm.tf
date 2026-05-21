resource "yandex_compute_instance" "db" {
  for_each = {
    for vm in var.each_vm : vm.vm_name => vm
  }

  name        = each.value.vm_name
  hostname    = each.value.vm_name
  platform_id = var.db_vm_platform_id
  zone        = var.vm_zone

  resources {
    cores         = each.value.cpu
    memory        = each.value.ram
    core_fraction = var.db_vm_core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.image_id
      size     = each.value.disk_volume
      type     = var.db_vm_disk_type
    }
  }

  network_interface {
    subnet_id          = var.existing_subnet_id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.example.id]
  }

  metadata = local.vm_metadata

  scheduling_policy {
    preemptible = true
  }
}
