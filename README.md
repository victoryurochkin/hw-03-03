# Домашнее задание к занятию «Управляющие конструкции в коде Terraform» - Юрочкин В.А.

## Цели задания

В рамках домашнего задания были отработаны основные управляющие конструкции Terraform:

- `count`
- `for_each`
- `dynamic`
- `templatefile`
- `file`
- `locals`
- работа с шаблонами Terraform
- генерация Ansible inventory-файла на основе созданной инфраструктуры

Все создаваемые виртуальные машины настроены как прерываемые (`preemptible = true`) для экономии средств в Yandex Cloud.

---

## Используемые версии

Версия Terraform соответствует требованию задания:

```bash
Terraform v1.12.2
```

В конфигурации указано требование:

```hcl
terraform {
  required_version = "~> 1.12.0"
}
```

Используемые провайдеры:

```hcl
terraform {
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
```

---

## Структура проекта

```text
.
├── ansible.tf
├── count-vm.tf
├── disk_vm.tf
├── for_each-vm.tf
├── locals.tf
├── main.tf
├── providers.tf
├── security.tf
├── variables.tf
├── templates/
│   └── inventory.tftpl
├── .gitignore
├── .terraformrc
└── README.md
```

Локальные файлы с секретами и состоянием не публикуются в GitHub:

```text
personal.auto.tfvars
*.auto.tfvars
*.tfstate
*.tfstate.*
.terraform/
```

---

# Задание 1

## Условие

Изучить проект, инициализировать его, выполнить код и приложить скриншот входящих правил группы безопасности в ЛК Yandex Cloud.

---

## Выполнение

Проект из директории `03/src` был изучен и инициализирован.

Были выполнены команды:

```bash
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
```

Проверка конфигурации завершилась успешно:

```text
Success! The configuration is valid.
```

Первоначально проект пытался создать новую VPC-сеть, но в облаке был достигнут лимит на количество сетей:

```text
Quota limit vpc.networks.count exceeded
```

Поэтому конфигурация была адаптирована на использование уже существующей VPC-сети:

```hcl
data "yandex_vpc_network" "develop" {
  network_id = var.existing_network_id
}
```

Переменная существующей сети:

```hcl
variable "existing_network_id" {
  type        = string
  description = "Existing Yandex Cloud VPC network ID"
  default     = "enpg169c3fi6e5amlgot"
}
```

После исправления Terraform создал группу безопасности:

```text
Plan: 1 to add, 0 to change, 0 to destroy.
```

Результат применения:

```text
yandex_vpc_security_group.example: Creation complete after 2s [id=enp4nk30t8q4df7m7mko]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```

---

## Созданная группа безопасности

Имя группы безопасности:

```text
example_dynamic
```

ID группы безопасности:

```text
enp4nk30t8q4df7m7mko
```

Входящие правила:

```text
TCP 22   SSH    0.0.0.0/0
TCP 80   HTTP   0.0.0.0/0
TCP 443  HTTPS  0.0.0.0/0
```

Исходящее правило:

```text
TCP 0-65365   0.0.0.0/0
```

---

<img width="991" height="1564" alt="image" src="https://github.com/user-attachments/assets/00d1a679-4435-44e3-bab3-6469e65cfed7" />


<img width="2272" height="1021" alt="image" src="https://github.com/user-attachments/assets/a74ff3e5-c677-4455-9a2d-9eadfccc95dd" />

<img width="2933" height="644" alt="image" src="https://github.com/user-attachments/assets/a3b99d32-3925-49c0-96a3-1e264b9cb650" />

<img width="2960" height="755" alt="image" src="https://github.com/user-attachments/assets/17a952e1-8374-470c-b76e-366822ede8d0" />

---

# Задание 2

## Условие

1. Создать файл `count-vm.tf`.
2. Описать в нём создание двух одинаковых ВМ `web-1` и `web-2`, используя `count`.
3. Назначить ВМ созданную в первом задании группу безопасности.
4. Создать файл `for_each-vm.tf`.
5. Описать в нём создание двух ВМ для баз данных с именами `main` и `replica`, используя `for_each`.
6. Использовать общую переменную типа `list(object(...))`.
7. ВМ из `count-vm.tf` должны создаваться после ВМ из `for_each-vm.tf`.
8. Использовать функцию `file` в `local`-переменной для чтения ключа `~/.ssh/id_rsa.pub`.
9. Выполнить код.

---

## Файл `locals.tf`

В файле `locals.tf` используется функция `file()` для чтения публичного SSH-ключа:

```hcl
locals {
  ssh_public_key = file(pathexpand("~/.ssh/id_rsa.pub"))

  vm_metadata = {
    ssh-keys = "${var.vm_ssh_user}:${local.ssh_public_key}"
  }

  web_vm_names = [
    for index in range(var.web_vm_count) : "${var.web_vm_name_prefix}-${index + 1}"
  ]
}
```

Так как в задании явно указан путь `~/.ssh/id_rsa.pub`, был создан RSA SSH-ключ:

```text
C:\Users\victo\.ssh\id_rsa
C:\Users\victo\.ssh\id_rsa.pub
```

---

## Создание web-ВМ через `count`

В файле `count-vm.tf` описаны две одинаковые ВМ:

```hcl
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
```

<img width="2308" height="1536" alt="image" src="https://github.com/user-attachments/assets/a6c1d471-ef4e-4575-af97-26d2fca253cc" />


Имена формируются не как `web-0` и `web-1`, а как:

```text
web-1
web-2
```

Для этого используется выражение:

```hcl
"${var.web_vm_name_prefix}-${index + 1}"
```

---

## Создание DB-ВМ через `for_each`

В файле `for_each-vm.tf` описаны две ВМ для баз данных:

```hcl
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
```

Переменная для DB-ВМ:

```hcl
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
```

---

## Группа безопасности и порядок создания

Всем ВМ назначена группа безопасности из задания 1:

```hcl
security_group_ids = [yandex_vpc_security_group.example.id]
```

Web-ВМ создаются после DB-ВМ с помощью явной зависимости:

```hcl
depends_on = [
  yandex_compute_instance.db
]
```

---

## Результат выполнения

Terraform показал план:

```text
Plan: 4 to add, 0 to change, 0 to destroy.
```

После применения были созданы ВМ:

```text
main     | ru-central1-b | RUNNING | 158.160.29.88  | 10.129.0.33
replica  | ru-central1-b | RUNNING | 158.160.23.166 | 10.129.0.26
web-1    | ru-central1-b | RUNNING | 158.160.30.225 | 10.129.0.9
web-2    | ru-central1-b | RUNNING | 111.88.150.171 | 10.129.0.12
```

Повторный запуск `terraform apply` показал:

```text
No changes. Your infrastructure matches the configuration.

Apply complete! Resources: 0 added, 0 changed, 0 destroyed.
```

<img width="2190" height="430" alt="image" src="https://github.com/user-attachments/assets/84505de4-0b85-43e7-86bd-8b60fc7ac9f3" />

<img width="2936" height="1210" alt="image" src="https://github.com/user-attachments/assets/51697d8f-0021-46ee-a2f9-e3cd28333614" />

---

# Задание 3

## Условие

1. Создать три одинаковых виртуальных диска размером 1 ГБ с помощью ресурса `yandex_compute_disk` и мета-аргумента `count` в файле `disk_vm.tf`.
2. Создать в этом же файле одиночную ВМ с именем `storage`.
3. Использовать блок `dynamic "secondary_disk"` и мета-аргумент `for_each` для подключения созданных дополнительных дисков.

---

## Создание дисков через `count`

В файле `disk_vm.tf` созданы три одинаковых диска:

```hcl
resource "yandex_compute_disk" "storage" {
  count = var.storage_disk_count

  name = "${var.storage_vm_name}-disk-${count.index + 1}"
  type = var.storage_disk_type
  zone = var.vm_zone
  size = var.storage_disk_size
}
```

Значения переменных:

```hcl
variable "storage_disk_count" {
  type        = number
  description = "Number of additional disks for storage VM"
  default     = 3
}

variable "storage_disk_size" {
  type        = number
  description = "Additional storage disk size in GB"
  default     = 1
}
```

---

## Создание ВМ `storage`

ВМ `storage` создана как одиночная ВМ без `count` и `for_each`:

```hcl
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
```

---

## Подключение дисков через dynamic-блок

```hcl
dynamic "secondary_disk" {
  for_each = yandex_compute_disk.storage

  content {
    disk_id     = secondary_disk.value.id
    auto_delete = true
  }
}
```

---

## Результат выполнения

Terraform показал план:

```text
Plan: 4 to add, 0 to change, 0 to destroy.
```

После применения:

```text
Apply complete! Resources: 4 added, 0 changed, 0 destroyed.
```

Проверка ВМ:

```text
storage | ru-central1-b | RUNNING | 158.160.25.107 | 10.129.0.31
```

Проверка дисков:

```text
storage-disk-1 | 1 GB | READY | attached to storage
storage-disk-2 | 1 GB | READY | attached to storage
storage-disk-3 | 1 GB | READY | attached to storage
```

<img width="2302" height="1079" alt="image" src="https://github.com/user-attachments/assets/49d6e5a1-ec06-4084-877f-f1cc9c308e92" />

<img width="2951" height="1405" alt="image" src="https://github.com/user-attachments/assets/f96e1b0d-52ad-4833-b9d3-ce78439fc8b0" />


---

# Задание 4

## Условие

1. В файле `ansible.tf` создать inventory-файл для Ansible.
2. Использовать функцию `templatefile` и файл-шаблон.
3. Передать в шаблон группы ВМ из заданий 2.1, 2.2 и 3.2, то есть 5 ВМ.
4. Inventory должен содержать 3 группы:
   - `webservers`
   - `databases`
   - `storage`
5. Inventory должен быть динамическим и корректно обрабатывать как группу из 2 ВМ, так и группу из 999 ВМ.
6. Добавить в inventory переменную `fqdn`.
7. Выполнить код.
8. Приложить скриншот получившегося файла.
9. Создать ветку `terraform-03`, закоммитить финальный код проекта и прислать ссылку на коммит.
10. Удалить все созданные ресурсы.

---

## Шаблон Ansible inventory

Был создан шаблон:

```text
templates/inventory.tftpl
```

Содержимое шаблона:

```hcl
[webservers]
%{ for vm in webservers ~}
${vm.name} ansible_host=${vm.external_ip} fqdn=${vm.fqdn}
%{ endfor ~}

[databases]
%{ for vm in databases ~}
${vm.name} ansible_host=${vm.external_ip} fqdn=${vm.fqdn}
%{ endfor ~}

[storage]
%{ for vm in storage ~}
${vm.name} ansible_host=${vm.external_ip} fqdn=${vm.fqdn}
%{ endfor ~}
```

---

## Файл `ansible.tf`

```hcl
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
```

---

## Подключение провайдера local

Для создания локального файла используется провайдер `hashicorp/local`:

```hcl
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
```

---

## Результат выполнения

Terraform показал план:

```text
Plan: 1 to add, 0 to change, 0 to destroy.
```

Ресурс:

```text
local_file.ansible_inventory
```

После применения:

```text
local_file.ansible_inventory: Creation complete

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```

---

## Сгенерированный inventory-файл

Команда:

```powershell
Get-Content .\inventory.ini
```

Вывод:

```ini
[webservers]
web-1 ansible_host=158.160.30.225 fqdn=web-1.ru-central1.internal
web-2 ansible_host=111.88.150.171 fqdn=web-2.ru-central1.internal

[databases]
main ansible_host=158.160.29.88 fqdn=main.ru-central1.internal
replica ansible_host=158.160.23.166 fqdn=replica.ru-central1.internal

[storage]
storage ansible_host=158.160.25.107 fqdn=storage.ru-central1.internal
```

<img width="2051" height="1285" alt="image" src="https://github.com/user-attachments/assets/45dfbc77-5346-4444-a564-5920792c40ad" />

---

## Финальная ветка и коммит

Для общего зачёта была создана новая ветка:

```text
terraform-03
```

Финальный код проекта был закоммичен в эту ветку.

Ссылка на ветку:

```text
https://github.com/victoryurochkin/hw-03-03/tree/terraform-03
```

<img width="2316" height="1596" alt="image" src="https://github.com/user-attachments/assets/2f7ccfc2-433b-4f74-827e-bbad8213f38c" />


## Удаление ресурсов

После создания скриншота inventory-файла и сохранения ссылки на коммит ресурсы необходимо удалить командой:

```bash
terraform destroy -auto-approve
```

Проверить удаление можно командами:

```bash
yc compute instance list
yc compute disk list
yc vpc security-group list
```

<img width="1706" height="1555" alt="image" src="https://github.com/user-attachments/assets/636308a0-c12a-45fa-9ec3-f92dd3dfbf4e" />

---

# Итог

Домашнее задание выполнено.

Созданы и применены Terraform-конфигурации для:

- группы безопасности Yandex Cloud;
- двух web-ВМ через `count`;
- двух DB-ВМ через `for_each`;
- одиночной ВМ `storage`;
- трёх дополнительных дисков через `count`;
- подключения дисков через `dynamic "secondary_disk"`;
- генерации Ansible inventory через `templatefile`.

Финальный код находится в ветке `terraform-03`.

Ссылка на коммит:
https://github.com/victoryurochkin/hw-03-03/commit/424bc2d24df31b70beae530ddbfdb501d964d160
