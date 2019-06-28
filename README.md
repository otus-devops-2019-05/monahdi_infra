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

