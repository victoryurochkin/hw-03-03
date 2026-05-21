terraform {
  required_version = "~> 1.12.0"

  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }

    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

provider "yandex" {
  token     = var.token
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
}
