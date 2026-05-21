###cloud vars
variable "token" {
  type        = string
  description = "OAuth-token; https://cloud.yandex.ru/docs/iam/concepts/authorization/oauth-token"
}

variable "cloud_id" {
  type        = string
  description = "https://cloud.yandex.ru/docs/resource-manager/operations/cloud/get-id"
}

variable "folder_id" {
  type        = string
  description = "https://cloud.yandex.ru/docs/resource-manager/operations/folder/get-id"
}

variable "default_zone" {
  type        = string
  default     = "ru-central1-a"
  description = "https://cloud.yandex.ru/docs/overview/concepts/geo-scope"
}
variable "default_cidr" {
  type        = list(string)
  default     = ["10.0.1.0/24"]
  description = "https://cloud.yandex.ru/docs/vpc/operations/subnet-create"
}

variable "vpc_name" {
  type        = string
  default     = "develop"
  description = "VPC network&subnet name"
}
variable "existing_network_id" {
  type        = string
  description = "Existing Yandex Cloud VPC network ID"
  default     = "enpg169c3fi6e5amlgot"
}

variable "existing_subnet_id" {
  type        = string
  description = "Existing subnet ID for virtual machines"
  default     = "e2lt5rhm75gtha6stmuh"
}

variable "vm_image_family" {
  type        = string
  description = "Yandex Cloud image family for all virtual machines"
  default     = "ubuntu-2204-lts"
}

variable "vm_ssh_user" {
  type        = string
  description = "Default SSH user for Ubuntu images"
  default     = "ubuntu"
}

variable "web_vm_count" {
  type        = number
  description = "Number of web virtual machines"
  default     = 2
}

variable "web_vm_name_prefix" {
  type        = string
  description = "Name prefix for web virtual machines"
  default     = "web"
}

variable "web_vm_platform_id" {
  type        = string
  description = "Platform ID for web virtual machines"
  default     = "standard-v1"
}

variable "web_vm_resources" {
  type = object({
    cores         = number
    memory        = number
    core_fraction = number
    disk_volume   = number
    disk_type     = string
  })

  description = "Resources for web virtual machines"

  default = {
    cores         = 2
    memory        = 2
    core_fraction = 5
    disk_volume   = 10
    disk_type     = "network-hdd"
  }
}

variable "each_vm" {
  type = list(object({
    vm_name     = string
    cpu         = number
    ram         = number
    disk_volume = number
  }))

  description = "List of DB virtual machines for for_each loop"

  default = [
    {
      vm_name     = "main"
      cpu         = 2
      ram         = 2
      disk_volume = 10
    },
    {
      vm_name     = "replica"
      cpu         = 2
      ram         = 4
      disk_volume = 20
    }
  ]
}

variable "db_vm_platform_id" {
  type        = string
  description = "Platform ID for DB virtual machines"
  default     = "standard-v3"
}

variable "db_vm_disk_type" {
  type        = string
  description = "Disk type for DB virtual machines"
  default     = "network-hdd"
}

variable "db_vm_core_fraction" {
  type        = number
  description = "Core fraction for DB virtual machines"
  default     = 20
}

variable "vm_zone" {
  type        = string
  description = "Availability zone for virtual machines"
  default     = "ru-central1-b"
}
