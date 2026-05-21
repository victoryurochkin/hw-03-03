data "yandex_compute_image" "ubuntu" {
  family = var.vm_image_family
}

resource "yandex_compute_instance" "web" {
  count = var.web_vm_count

  name        = local.web_vm_names[count.index]
  hostname    = local.web_vm_names[count.index]
  platform_id = var.web_vm_platform_id
  zone        = var.vm_zone

  resources {
    cores         = var.web_vm_resources.cores
    memory        = var.web_vm_resources.memory
    core_fraction = var.web_vm_resources.core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.image_id
      size     = var.web_vm_resources.disk_volume
      type     = var.web_vm_resources.disk_type
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

  depends_on = [
    yandex_compute_instance.db
  ]
}
