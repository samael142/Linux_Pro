Домашнее задание 1
Обновление ядра системы.


Смотрим версию ядра:
```bash
uname -r
```
Вывод: 
6.8.0-107-generic

Скачиваем пакеты:
```bash
mkdir -p ~/new_kernel && cd ~/new_kernel
wget https://kernel.ubuntu.com/mainline/v6.19/amd64/linux-headers-6.19.10-061910_6.19.10-061910.202603251147_all.deb
wget https://kernel.ubuntu.com/mainline/v6.19/amd64/linux-headers-6.19.10-061910-generic_6.19.10-061910.202603251147_amd64.deb
wget https://kernel.ubuntu.com/mainline/v6.19/amd64/linux-image-unsigned-6.19.10-061910-generic_6.19.10-061910.202603251147_amd64.deb
wget https://kernel.ubuntu.com/mainline/v6.19/amd64/linux-modules-6.19.10-061910-generic_6.19.10-061910.202603251147_amd64.deb
```
Устанавливаем всё:
```bash
sudo dpkg -i *.deb
```
Проверяем, что ядро появилось в boot
```bash
ls -la /boot/
```
Назначаем ядро по умолчанию:
```bash
sudo update-grub
sudo grub-set-default 0
```

Перезагружаемся, проверяем:
```bash
uname -r
```
Вывод: 
6.19.10-061910-generic
