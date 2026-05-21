resource "yandex_compute_disk" "storage" {
  count = var.storage_disk_count

  name = "${var.storage_vm_name}-disk-${count.index + 1}"
  type = var.storage_disk_type
  zone = var.vm_zone
  size = var.storage_disk_size
}

resource "yandex_compute_instance" "storage" {
  name        = var.storage_vm_name
  hostname    = var.storage_vm_name
  platform_id = var.storage_vm_platform_id
  zone        = var.vm_zone

  resources {
    cores         = var.storage_vm_resources.cores
    memory        = var.storage_vm_resources.memory
    core_fraction = var.storage_vm_resources.core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.image_id
      size     = var.storage_vm_resources.disk_volume
      type     = var.storage_vm_resources.disk_type
    }
  }

  dynamic "secondary_disk" {
    for_each = yandex_compute_disk.storage

    content {
      disk_id     = secondary_disk.value.id
      auto_delete = true
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
