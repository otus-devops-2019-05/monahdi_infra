# monahdi_infra
monahdi Infra repository
## HW3
Created two hosts. The first is *bastion* host has a public ip, and the second is *someinternalhost* has no public ip.
Goinng to *someinternalhost*, need to connect VPN at bastion
``` 
openvpn cloud-bastion.ovpn 
```
and then connecting to *someinternalhost* 
``` 
ssh -i ~/.ssh/<username> <username>@< IP someinternalhost> 
```

Connecting data:
``` 
bastion_IP = 34.77.141.228 
someinternalhost_IP = 10.132.0.3
```

## HW4
Наконец-то установил русский язык на виртуалку с Ubuntu, можно писать ридми на великом и могучем!
Данные для автопроверки ДЗ:
```
testapp_IP = 35.233.3.109
testapp_port = 9292
```

Так вот, могучее ДЗ4.
Создали инстанс через SDK GCP, командой из предоставленного к ДЗ листинга:
```
gcloud compute instances create reddit-app\
  --boot-disk-size=10GB \
  --image-family ubuntu-1604-lts \
  --image-project=ubuntu-os-cloud \
  --machine-type=g1-small \
  --tags puma-server \
  --restart-on-failure
  ```
  Далее, необходимо поставить руби. Используем скрипт:
  ```
#!/bin/bash
# Ruby install
sudo apt update
sudo apt install -y ruby-full ruby-bundler build-essential
```
БД будет Монго, ставим скриптом:
```
#!/bin/bash
# Install and start MongoDB
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv EA312927
sudo bash -c 'echo "deb http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.2 multiverse" > /etc/apt/sources.list.d/mongodb-org-3.2.list'
sudo apt update
sudo apt install -y mongodb-org
sudo systemctl start mongod
sudo systemctl enable mongod
```
И, наконец, качаем и врубаем приложение скриптом:
```
#!/bin/bash
# Dowload and start application
git clone -b monolith https://github.com/express42/reddit.git
cd reddit && bundle install
puma -d
ps aux | grep puma
```
###  Доп.задание
Startup script для авторазвертывания приложения на создаваемом инстансе:

```
#!/bin/bash
# This is startup skript. It install ruby, MongoDB and deploy puma-app
#First to install ruby
sudo apt update
sudo apt install -y ruby-full ruby-bundler build-essential
#Second to install MongoDB
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv EA312927
sudo bash -c 'echo "deb http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.2 multiverse" > /etc/apt/sources.list.d/mongodb-org-3.2.list'
sudo apt update
sudo apt install -y mongodb-org
sudo systemctl start mongod
sudo systemctl enable mongod
#End to deploy application
git clone -b monolith https://github.com/express42/reddit.git
cd reddit && bundle install
puma -d
ps aux | grep puma
```
Используемая команда gloud:
```
gcloud compute instances create reddit-app1 --scopes storage-ro \
--metadata startup-script-url=gs://my-first-startupscript/startup.sh\
--boot-disk-size=10GB \
--image-family ubuntu-1604-lts \
--image-project=ubuntu-os-cloud \
--machine-type=g1-small \
--tags puma-server \
--restart-on-failure
```
Команда для создания правила брендмаура:
```
gcloud compute firewall-rules create default-puma-server \
    --network default\
    --priority 1000\
    --direction ingress\
    --action allow\
    --target-tags puma-server\
    --source-ranges 0.0.0.0/0 \
    --rules tcp:9292
```

## HW5
Установили Packer. На линукса можно поставить следующим путем: сначала
```
$ mkdir -p $(go env GOPATH)/src/github.com/hashicorp && cd $_
$ git clone https://github.com/hashicorp/packer.git
$ cd packer
```
затем, переносим бинарный файл в bin и на последок делаем
```
make dev
```
Проверить работоспособность можно либо 
```
packer -v
```
либо просто
```
packer
```
Далее, поставили ADC
```
$ gcloud auth application-default login
```
и сделали первый шаблон для Packer.
Поначалу, шаблон состоял только из секции build следующего вида
```
{
    "builders": [
        {
            "type": "googlecompute",
            "project_id": "infra-123456",
            "image_name": "reddit-base-{{timestamp}}",
            "image_family": "reddit-base",
            "source_image_family": "ubuntu-1604-lts",
            "zone": "europe-west1-b",
            "ssh_username": "appuser",
            "machine_type": "f1-micro"
        }
    ]
}
```
Добавили немного провиженинга вида
```
"provisioners": [
        {
            "type": "shell",
            "script": "scripts/install_ruby.sh",
            "execute_command": "sudo {{.Path}}"
        },
        {
            "type": "shell",
            "script": "scripts/install_mongodb.sh",
            "execute_command": "sudo {{.Path}}"
        }
```
И наконе проверели работоспособность получившегося образа. Для начала проверка на ошибки
```
$ packer validate ./ubuntu16.json
```
ошибок не выявила, по этому смело запустили билд
```
$ packer build ubuntu16.json
```
Все прекрасно взлетело. Сдеплоили приложение, создав ВМ из получившегося образа, к которому подключились по ssh и поставили приложение из предыдущего ДЗ
```
$ git clone -b monolith https://github.com/express42/reddit.git
$ cd reddit && bundle install
$ puma -d
```
Приложение прекрасно взлетело.
Далее, добавили пару переменных в .json 
```
 "variables": {
        "project_id": "",
        "source_image_family": "",
        "machine_type": ""
    }
```
поместили их значения в json-файл variables, который находится в .gitignore.Пример файла со значением переменных называется variables.json.example.
Кроме того, добавили пару параметров build в конечную версию образа

```
"builders": [
        {
            "type": "googlecompute",
            "project_id": "{{user `project_id`}}",
            "image_name": "reddit-base-{{timestamp}}",
            "image_family": "reddit-base",
            "source_image_family": "{{user `source_image_family`}}",
            "zone": "europe-west1-d",
            "ssh_username": "appuser",
            "machine_type": "{{user `machine_type`}}",
            "image_description": "This is test description",
            "disk_size": "50",
            "disk_type": "pd-standard",
            "network": "default",
            "tags": "luma-server"
        }
```
Получил инфу для выполнения доп.задания, попробую сделать после изучения)

##HW6
Прекрасная штука Terraform. Удаляем через веб-морду GCP ключи, что ьбы чуть позже добавить их в метаданные машины через Терру.
Качаем Терру, в моем случае tar архив, распаковываем и добавляем бинарник в PATH.
Так как с ДЗ затянул, читая чатик и учась на чужих граблях, сразу ставлю версию 0.11.1)
Проверяем установку командой
```
terraform -v
```
Создаем файл main.tf, который и будет главным конфигурационным файлом. Предусмотрительно сразу в .gitignore  добавляем все файлы Терры, которые не желательно светить в публичном репозитории
```
*.tfstate
*.tfstate.*.backup
*.tfstate.backup
*.tfvars
.terraform/
```
Далее, в секции провайдеров определяем GCP
```
terraform {
  # Версия terraform
  required_version = "0.11.1"
}

provider "google" {
  # Версия провайдера
  version = "2.0.0"

  # ID проекта
  project = "$my_project_ID"
  region  = "$Region"
}
```
Грузим провайдер с помощью 
```
terraform init
```
В конфигурационный фал добавляем ресурс для VM
```
resource "google_compute_instance" "app" {
 name = "reddit-app"
 machine_type = "g1-small"
 zone = "europe-west1-b"
 # определение загрузочного диска
 boot_disk {
  initialize_params {
   image = "reddit-base"
    }
   }
 # определение сетевого интерфейса
 network_interface {
  # сеть, к которой присоединить данный      интерфейс
  network = "default"
  # использовать ephemeral IP для доступа  из   Интернет
  access_config {}
 }
}
```
Первый раз используем команду для планирования изменений 
```
terraform plan
```
И отправляем Терру разворачивать ВМ, предварительно задав аргумент автоподтверждения
```
terraform apply -auto-approve=true
```
После выполнения команды появляется файл с описанием состояния terraform.tfstate
Несколькими вариантами пыаемся найти в .state-файле внешний адрес ВМ, сначала руками, потом консрукцией 
```
terraform show | grep nat_ip
```
Однако, более правильный путь - это определить для внешнего адреса output-переменную. Создаем отдельный файл outputs.tf, в котором делается следующая запись 
```
output "app_external_ip" {
  value=$google_compute_instance.app.network_interface.0.access_config.0.assigned_nat_ip}"
}
```
Далее делаем 
```
terraform refresh
```
что бы output-переменная приняла значение, и... сталкиваемся с первой опечаткой в методичке) Корректируем файл outputs, выставив у атрибутов ресурса просто nat_ip вмсето assignet_nat_ip.
Снова
```
terraform refresh
```
переменная принимает значение, которое смотрим с помощью 
```
terraform output
```
Переменную для определения адреса задали, однако, подключится по ssh к ВМ не удается...Так как удалены ключи в начале упражнения. Задаем ключи в конфигурационном файле через метаданные
```
metadata {
    # путь до публичного ключа
    ssh-keys = "appuser:${file(public_key-path)}"
  }
  ```
Прогоняем эти изменения через plan и apply.
Теперь к ВМ можно подключитсья по ssh.
Добавляем в конфигурационный файл ресурс правила для фаервола
```
resource "google_compute_firewall" "firewall_puma" {
name = "allow-puma-default"
# Название сети, в которой действует правило
network = "default"
# Какой доступ разрешить
allow {
protocol = "tcp"
ports = ["9292"]
}
# Каким адресам разрешаем доступ
source_ranges = ["0.0.0.0/0"]
# Правило применимо для инстансов с перечисленными тэгами
target_tags = ["reddit-app"]
}
```
Планируем и применяем изменения через уже полюбившуюся последовательность plan + apply.
Внезапно, правило применяется только к ВМ с тегом. Добавляем в ресурс ВМ нужный тег
```
tags = ["reddit-app"]
```
И снова планируем и применяем изменения.
Пора поиграться с проивженерами.
Создаем директорию files.
В нее кладем файл puma.service с примерным содержанием
```
[Unit]
Description=Puma HTTP Server
After=network.target

[Service]
Type=simple
User=appuser
WorkingDirectory=/home/appuser/reddit
ExecStart=/bin/bash -lc 'puma'
Restart=always

[Install]
WantedBy=multi-user.target
```
А также файлик deploy.sh с
```
#!/bin/bash
set -e

APP_DIR=${1:-$HOME}

git clone -b monolith https://github.com/express42/reddit.git $APP_DIR/reddit
cd $APP_DIR/reddit
bundle install

sudo mv /tmp/puma.service /etc/systemd/system/puma.service
sudo systemctl start puma
sudo systemctl enable puma
```
Теперь можно забабахать провижинер в конфигурационный файл, который скоприует файл puma.service
```
provisioner "file" {
source = "files/puma.service"
destination = "/tmp/puma.service"
}
```
Еще один, который запустит скрипт делоя
```
provisioner "remote-exec" {
script = "files/deploy.sh"
}
```
А также, определить параметры поключения провижионеров, забив перед ними коннектор
```
connection {
type = "ssh"
user = "appuser"
agent = false
# путь до приватного ключа
private_key = "${file("~/.ssh/appuser")}"
}
```
Что бы проверить работу провижионеров, нужно пересоздать ВМ. Сдлеать это можно попросив Терру при следующем apply пересоздать ВМ
```
terraform taint google_compute_instance.app
```
Снова планируем и применяем изменения. Смотрим, как взлетела пума.
Далее, разбираемся с input-переменными. Создаем файл variables.tf для описания переменных. Выглядит он примерно так
```
variable project {
description = "Project ID"
}
variable region {
description = "Region"
# Значение по умолчанию
default = "europe-west1"
}
variable public_key_path {
# Описание переменной
description = "Path to the public key used for ssh access"
}
variable disk_image {
description = "Disk image"
}
```
В конфигурационном файле переменные определяются через синтаксис
```
"${var.var_name}"
```
Меняем несколько параметров в конфигурационном файле на переменные
```
provider "google" {
version = "2.0.0"
project = "${var.project}"
region = "${var.region}"
}
```
```
...
boot_disk {
initialize_params {
image = "${var.disk_image}"
}
}
...
metadata {
ssh-keys = "appuser:${file(var.public_key_path)}"
}
...
```
Определяются переменные в файле terraform.tfvars
Создаем его с примерно такого вида
```
project = "infra-179015"
public_key_path = "~/.ssh/appuser.pub"
disk_image = "reddit-base"
```
Пересоздаем все ресурсы с помощью последовательности команд
```
terraform destroy
terraform plan
terraform apply
```
Сталкиваюсь со своей опечаткой в конфиг файле, переименовываю переменную из publick_key_pass в public_key-pass.
Снова дестрой, взлет, поехали)

Далее, добавляем в описание переменных (файл variables.tf) переменные для коннектора ключа провижионеров и переменную для зоны. В переменную для зоны задаю параметр по умолчанию. Форматирую файлы конфигурации командой 
```
terraform fmt
```
и создаю файл с примером определения переменных terraform.tfvars.example.
Задания со звездочкой приходится оставлять на потом, ибо есть уже долги...
