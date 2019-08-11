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

## HW6
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
Пора поиграться с провиженерами.
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
Теперь можно забабахать провиженер в конфигурационный файл, который скоприует файл puma.service
```
provisioner "file" {
source = "files/puma.service"
destination = "/tmp/puma.service"
}
```
Еще один, который запустит скрипт деплоя
```
provisioner "remote-exec" {
script = "files/deploy.sh"
}
```
А также, определить параметры подключения провижеонеров, забив перед ними коннектор
```
connection {
type = "ssh"
user = "appuser"
agent = false
# путь до приватного ключа
private_key = "${file("~/.ssh/appuser")}"
}
```
Чтобы проверить работу провижионеров, нужно пересоздать ВМ. Сделать это можно попросив Терру при следующем apply пересоздать ВМ
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

## HW7
Подправил несколько опечаток в readmy и надо бы это сделать покомпактнее...
Добавляем в конфиг-файл main.tf правило для фаервола, касающееся доступа по ssh
```
resource "google_compute_firewall" "firewall_ssh" {
name = "default-allow-ssh"
network = "default"
allow {
protocol = "tcp"
ports = ["22"]
}
source_ranges = ["0.0.0.0/0"]
}
```
Для того, что бы Терраформ знал о том, что правило уже существует, импортируем его из уже развернутой ифнраструктуры командой 
```
$ terraform import google_compute_firewall.firewall_ssh default-allow-ssh
```
Задаем адрес для инстанса приложения как внешний ресурс
```
resource "google_compute_address" "app_ip" {
name = "reddit-app-ip"
}
```
после чего удаляем зарезервированный под бастион адрес, ибо бесплатная версия GCP...
Меняем конфигурацию сетевого инфтерфейса для инстанса, что бы воспользоваться тем самым адресом
```
access_config = {
nat_ip = "${google_compute_address.app_ip.address}"
```
При пересоздании ресурсов видим, что Терра сначала создает ресурс с адресом, а уже потом начинает созадавть инстанс. Это прямая зависимость.
Создаем через Packer два новых образа, отдельно для БД и приложения.
Разбиваем конфиг-файл Терры на два - для приложения и для БД. Также, правило для доступа по ssh выносим в отедльный файл-конфиг. В итоге в main-файле остатется только конфигурация провайдера. Все это было подготовкой к использованию модулей. Далее создаем отдельные дирректории для модуля прилодения и модуля БД. В каждом из них свой конфиг-файл и файлы переменных. В файле main-конфига остаются только секции для вызова модулей
```
provider "google" {
version = "2.0.0"
project = "${var.project}"
region = "${var.region}"
}
module "app" {
source = "modules/app"
public_key_path = "${var.public_key_path}"
zone = "${var.zone}"
app_disk_image = "${var.app_disk_image}"
} 

module "db" {
source = "modules/db"
public_key_path = "${var.public_key_path}"
zone = "${var.zone}"
db_disk_image = "${var.db_disk_image}"
} 
```
Для того, что бы начать использовать модули, запускаем командой
```
terraform get
```
их загрузку.
В основном файле выходных переменных меняем значение на
```
output "app_external_ip" {value = "${module.app.app_external_ip}"
}
```
дабы получить значение, а не ссылаться на уже не существующий ресурс.
Далле, по анологии создаем модуль vpc, который по сути копирует созданный ранее файл vpc.tf. С помощью небольшой параметризации данного модуля, задаем значение адреса как диапазон. Теперь в основном конфиг-файле можно задать sourceRange равный своему IP-адресу. В этом случае подключаться к создаваемым инстансам можно будет только с одного адреса.
Создаем два окружения, stage и prod, на основе основного файла конфигурации) Отличаются эти два окружения только уровнем доступа к инстансам по ssh. В каждом делаем 
```
terraform init
terraform apply
terraform destroy
```
для проверки работоспособности.
Приводим конфиг=файлы к божескому виду с помощью
```
terramorm fmt
```
Сносим основной конфиг и на его месте делаем конфиг для двух бакетов
```
provider "google" {
  version = "2.0.0"
  project = "${var.project}"
  region  = "${var.region}"
}

module "storage-bucket" {
  source  = "SweetOps/storage-bucket/google"
  version = "0.1.1"
  name    = ["storage-bucket-firsttestbacket", "storage-bucket-secondtestbacked"]
}

output storage-bucket_url {
  value = "${module.storage-bucket.url}"
}
```
Инициируем Терру, проверяем создание бакетов и все дестроим.
Доп задания как обычно, с надеждой на лучшие времена...

## HW8
С горем пополам (ибо много безуспешных попыток поставить Ansible версии 2.4 ни к чему не привели), ставим Ansible. ПОднимаем stage-инфру Терраформом, после чего проводим пару упражнений. Создаем инвентори файл с простым описанием одной машины
```
appserver ansible_host=35.195.186.154 ansible_user=appuser \
ansible_private_key_file=~/.ssh/appuser
```
И пингуем его
```
ansible appserver -i ./inventory -m ping
```
Ту же процедуру повторяемдля ВМ с БД.
Далее, создаем простой конфиг-файл
```
[defaults]
inventory = ./inventory
remote_user = appuser
private_key_file = ~/.ssh/appuser
host_key_checking = False
retry_files_enabled = False
```
И теперь меняем файл инвентори на более простой
```
appserver ansible_host=35.195.74.54
dbserver ansible_host=35.195.162.174
```
Продолжаем упражняться с модулем command, который позволяет запускать произвольные команды
```
ansible dbserver -m command -a uptime
```
после чего создаем пару групп хостов в инвентори для удобства
```
[app] #Это название группы
appserver ansible_host=35.195.74.54 #Cписок хостов в данной группе

[db]
dbserver ansible_host=35.195.162.174
```
и теперь модно отдавать команды на целую группу
```
ansible app -m ping
```
Дальше, переносим наш инвентори в формат YAML, переопределяем путь к инвентори и пингуем все машины
```
ansible all -m ping -i inventory.yml
```
Проверяем с помощью уже известного модуля command установленые на ВМ компоненты
```
$ ansible app -m command -a 'ruby -v'

$ ansible app -m command -a 'bundler -v'
```
Все круто, вот только command не запускает shell, по этому не может выполнять последовательности команд, например.
Для этого используется модуль shell
```
$ ansible app -m shell -a 'ruby -v; bundler -v'
```
Упражняемся с проверкой статуса БД. Можно это сделать с помощью модулей command и shell
```
$ ansible db -m command -a 'systemctl status mongod'

$ ansible db -m shell -a 'systemctl status mongod'
```
Однако, куда интереснее выводы systemd
```
$ ansible db -m systemd -a name=mongod
```
и service
```
$ ansible db -m service -a name=mongod
```
Модули возвращают набор переменных, которые можно использовать в последующем коде.
Дальще, различными способами пытаемся снова склонировать git,который уже есть на серверах. Команды проходят, но changed возвращается с false, что означает отсутсвие изменений. Для интереса, реализуем простой плейбук с той же целью
```
- name: Clone
  hosts: app
  tasks:
    - name: Clone repo
      git:
        repo: https://github.com/express42/reddit.git
        dest: /home/appuser/reddit
```
запускаем его
```
ansible-playbook clone.yml
```
и снова не получаем изменений. Для практики, сноси дирректорию с git командой
```
ansible app -m command -a 'rm -rf ~/reddit'
```
после чего повторный запуск плейбука возвращается с изменениями на appserver.

### HW9
Создаем единый плейбук для управления и деплоя нашего приложения. Начинаем содного сценария на плейбук. Перво наперво указываем, для какой группы хостов будет действовать плейбук:
```
- name: Configure hosts & deploy application # 
  hosts: all
```
Пишем первый таск, который позволит указать приложению на месторасположение БД. Сразу добавляем тег, даы иметь возможность запускать отдельыне таски, а не весь сценарий.
```
tasks:
- name: Change mongo config file
  become: true 
  template:
    src: templates/mongod.conf.j2
    dest: /etc/mongod.conf
    mode: 0644
  tags: db-tag
```
Создаем шаблон конфига для таска выше
```
# Where and how to store data.
storage:
  dbPath: /var/lib/mongodb
  journal:
    enabled: true

# where to write logging data.
systemLog:
  destination: file
  logAppend: true
  path: /var/log/mongodb/mongod.log

# network interfaces
net:
  port: {{ mongo_port | default('27017') }}
  bindIp: {{ mongo_bind_ip }}
```
После чего можно прогнать наш сценарий. Для пробного прогона используется ключ --check, аналог terraform plan. Также указываем тег через ключ --limit, что бы запустить определенный таск
```
ansible-playbook reddit_app.yml --check --limit db
```
После ошибки, задаем в плейбуке переменную, которую использовали в шаблоне, но не объявили
```
- name: Configure hosts & deploy application
  hosts: all
  vars: 
    mongo_bind_ip: 0.0.0.0 
  tasks:
  - name: Change mongo config file
    become: true
    template:
      src: templates/mongod.conf.j2
      dest: /etc/mongod.conf
      mode: 0644
    tags: db-tag
```
После чего пробный прогон проходит успешно и мы можем запустить плейбук, увидив изменения, которые он произведет.
Добавляем в плейбук handlers - таск, который вызывается только при оповещении от других тасков. В нашем случае мы хотим, что бы БД преезапускалась после отработки нашим таском.
```
- name: Configure hosts & deploy application
  hosts: all
  vars: 
    mongo_bind_ip: 0.0.0.0 
  tasks:
  - name: Change mongo config file
    become: true
    template:
      src: templates/mongod.conf.j2
      dest: /etc/mongod.conf
      mode: 0644
    tags: db-tag
    notify: restart mongod
  handlers:
  - name: restart mongod
    become: true
    service: name=mongod state=restarted
```
Применяем плейбук.
Далее, создаем юнит-файл для будущего переноса на сервер приложения
```
[Unit]
Description=Puma HTTP Server
After=network.target

[Service]
Type=simple
EnvironmentFile=/home/appuser/db_config
User=appuser
WorkingDirectory=/home/appuser/reddit
ExecStart=/bin/bash -lc 'puma'
Restart=always

[Install]
WantedBy=multi-user.target
```
В юнит-файле есть строка для чтения переменных. Создаем файл для этого со следующим содержанием
```
DATABASE_URL={{ db_host }}
```

Добавляем в сценарий переменную адреса сервера (внутренний адрес базы). Добавляем таск для копирования файла (модуль copy) и автозапуска приложения (модуль systemd). В таски также добавляем задачу для копирования созданного ранее шаблона с переменой адреса. Кроме того, добавляем handlers, указывающий на изменения юнит-файла и отправляющий его перечитывать
```
- name: Configure hosts & deploy application
  hosts: all
  vars: 
    mongo_bind_ip: 0.0.0.0
    db_host: 10.132.0.2
  tasks:
  - name: Change mongo config file
    become: true
    template:
      src: templates/mongod.conf.j2
      dest: /etc/mongod.conf
      mode: 0644
    tags: db-tag
    notify: restart mongod

  - name: Add unit file for Puma
    become: true
    copy:
      src: files/puma.service
      dest: /etc/systemd/system/puma.service
    tags: app-tag
    notify: reload puma

  - name: Add config for DB connection
    template:
      src: templates/db_config.j2
      dest: /home/appuser/db_config
    tags: app-tag

  - name: enable puma
    become: true
    systemd: name=puma enabled=yes
    tags: app-tag

  handlers:
  - name: restart mongod
    become: true
    service: name=mongod state=restarted
  
  - name: restart mongod
    become: true
    service: name=mongod state=restarted

  - name: reload puma
    become: true
    systemd: name=puma state=restarted
```
Делаем пробный прогон плейбука и применяем его к хостам app (только сценарии app-tag)
```
$ ansible-playbook reddit_app.yml --check --limit app --tags app-tag
$ ansible-playbook reddit_app.yml --limit app --tags app-tag
```
Переходим к деплою. Добавляем через модули git и bundl клонирование актуальной репы приложения и установку рубей
```
tasks:
...
- name: Fetch the latest version of application code
  git:
    repo: 'https://github.com/express42/reddit.git'
    dest: /home/appuser/reddit
    version: monolith # <-- Указываем нужную ветку
  tags: deploy-tag
  notify: reload puma
- name: Bundle install
  bundler:
    state: present
    chdir: /home/appuser/reddit
  tags: deploy-tag
```
Деплоим
```
$ ansible-playbook reddit_app.yml --check --limit app --tags deploy-tag
$ ansible-playbook reddit_app.yml --limit app --tags deploy-tag
```
Все круто, на каждый раз для запуска нужных сценариев нужно указывать необходимые теги. Не очень удобно и для решения этого вопроса предлагается разбить большой сценарий на несколько поменьше, каждый со своей ролью.
Сценарий для БД
```
- name: Configure MongoDB
  hosts: db
  tags: db-tag
  become: true
  vars:
    mongo_bind_ip: 0.0.0.0
  tasks:
    - name: Change mongo config file
      template:
        src: templates/mongod.conf.j2
        dest: /etc/mongod.conf
        mode: 0644
      notify: restart mongod

  handlers:
  - name: restart mongod
    service: name=mongod state=restarted
```
Сценарий для инстанса приложения
```
- name: Configure MongoDB
  hosts: db
  tags: db-tag
  become: true
  vars:
    mongo_bind_ip: 0.0.0.0
  tasks:
    - name: Change mongo config file
      template:
        src: templates/mongod.conf.j2
        dest: /etc/mongod.conf
        mode: 0644
      notify: restart mongod

  handlers:
  - name: restart mongod
    service: name=mongod state=restarted

- name: Configure App
  hosts: app
  tags: app-tag
  become: true
  vars:
   db_host: 10.132.0.2
  tasks:
    - name: Add unit file for Puma
      copy:
        src: files/puma.service
        dest: /etc/systemd/system/puma.service
      notify: reload puma

    - name: Add config for DB connection
      template:
        src: templates/db_config.j2
        dest: /home/appuser/db_config
        owner: appuser
        group: appuser

    - name: enable puma
      systemd: name=puma enabled=yes

  handlers:
  - name: reload puma
    systemd: name=puma state=restarted
```
И сценарий для деплоя. Итоговый сценарий
```
- name: Configure MongoDB
  hosts: db
  tags: db-tag
  become: true
  vars:
    mongo_bind_ip: 0.0.0.0
  tasks:
    - name: Change mongo config file
      template:
        src: templates/mongod.conf.j2
        dest: /etc/mongod.conf
        mode: 0644
      notify: restart mongod

  handlers:
  - name: restart mongod
    service: name=mongod state=restarted


- name: Configure App
  hosts: app
  tags: app-tag
  become: true
  vars:
   db_host: 10.132.0.2
  tasks:
    - name: Add unit file for Puma
      copy:
        src: files/puma.service
        dest: /etc/systemd/system/puma.service
      notify: reload puma

    - name: Add config for DB connection
      template:
        src: templates/db_config.j2
        dest: /home/appuser/db_config
        owner: appuser
        group: appuser

    - name: enable puma
      systemd: name=puma enabled=yes

  handlers:
  - name: reload puma
    systemd: name=puma state=reloaded


- name: Deploy App
  hosts: app
  tags: deploy-tag
  tasks:
    - name: Fetch the latest version of application code
      git:
        repo: 'https://github.com/express42/reddit.git'
        dest: /home/appuser/reddit
        version: monolith
      notify: restart puma

    - name: bundle install
      bundler:
        state: present
        chdir: /home/appuser/reddit

  handlers:
  - name: restart puma
    become: true
    systemd: name=puma state=restarted
```

Пересоздаем инфраструктуру и запускаем каждый сценарий
```
$ ansible-playbook reddit_app2.yml --tags db-tag --check
$ ansible-playbook reddit_app2.yml --tags db-tag
$ ansible-playbook reddit_app2.yml --tags app-tag --check
$ ansible-playbook reddit_app2.yml --tags app-tag
$ ansible-playbook reddit_app2.yml --tags deploy-tag --check
$ ansible-playbook reddit_app2.yml --tags deploy-tag
```
Стало удобнее, но не на много. По этому для большего удобства...создаем несколько плейбуков) Также, как и по сценариям, по трем ролям: приложение, БД, деплой.
Убираем из сценариев теги и разносим по плейбукам. Для БД:
```
- name: Configure MongoDB
  hosts: db
  become: true
  vars:
    mongo_bind_ip: 0.0.0.0
  tasks:
    - name: Change mongo config file
      template:
        src: templates/mongod.conf.j2
        dest: /etc/mongod.conf
        mode: 0644
      notify: restart mongod

  handlers:
  - name: restart mongod
    service: name=mongod state=restarted
```
Для приложения
```
- name: Configure App
  hosts: app
  become: true
  vars:
   db_host: 10.132.0.2
  tasks:
    - name: Add unit file for Puma
      copy:
        src: files/puma.service
        dest: /etc/systemd/system/puma.service
      notify: reload puma

    - name: Add config for DB connection
      template:
        src: templates/db_config.j2
        dest: /home/appuser/db_config
        owner: appuser
        group: appuser

    - name: enable puma
      systemd: name=puma enabled=yes

  handlers:
  - name: reload puma
    systemd: name=puma state=restarted
```
И для деплоя
```
- name: Deploy App
  hosts: app
  tasks:
    - name: Fetch the latest version of application code
      git:
        repo: 'https://github.com/express42/reddit.git'
        dest: /home/appuser/reddit
        version: monolith
      notify: restart puma

    - name: bundle install
      bundler:
        state: present
        chdir: /home/appuser/reddit

  handlers:
  - name: restart puma
    become: true
    systemd: name=puma state=restarted
```
А теперь можно сделать "главный" плейбук, который будет включать все остальные
```
- import_playbook: db.yml
- import_playbook: app.yml
- import_playbook: deploy.yml
```
Пересоздаем инфру, меняем параметры в инвентори и погнали
```
$ ansible-playbook site.yml --check
$ ansible-playbook site.yml
```
И наконец то, что заняло три часа траблшутинга и ни к чему не привело)
Меняем провиженеры в конфигурации Пакера со скриптов на плейбуки Ансибла.
Плейбук для образа приложения
```

- name: Install Ruby
  hosts: all
  become: true
  tasks:
  - name: Update apt packages
    apt: 
      update_cache: true
  - name:
    apt:
      name: "{{packages}}"
      state: present
    vars:
      packages:
      - ruby-full
      - ruby-bundler
      - build-essential
```
и плейбук для образа БД
```
- name: Install DB
  hosts: all
  become: true

  tasks:
    - name: Install ppa key
      apt_key:
        keyserver: hkp://keyserver.ubuntu.com:80
        id: EA312927

    - name: Update apt packages
      apt: 
        update_cache: true

    - name: App repo
      apt_repository:
        repo: deb [ arch=amd64,arm64 ] http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.2 multiverse
        state: present

    - name: Install DB
      apt:
        name: mongodb-org
        state: present

    - name: Enable autostart DB
      systemd:
        name: mongod
        enabled: yes
```
Меняем провижионеры в Пакере
```
"provisioners": [
  {
    "type": "ansible",
    "playbook_file": "ansible/packer_app.yml"
  }
]
```
и
```
"provisioners": [
  {
    "type": "ansible",
    "playbook_file": "ansible/packer_db.yml"
  }
]
Ключ force - для слабаков, по этому сносим имеющиеся образы и начинаем подымать те, что только что создали...
И тут внезапно начинаются какие то сложности...Образ приложения поднимается при последней конфигурации, а вот БД ни в какую не хочет...Проверки Тревиса проходят, то есть гипотетически все корректно. Но образ удален и новый не поднимается) Отступать никуда...После трех часов мучений и помощи сообщества, в плейбук БД при установке базы был добавлен параметр
```
allow_unauthenticated: yes
```
так как в противном случае GCP по неведомым причинам считаем установку БД установкой из недоверенного источника...
