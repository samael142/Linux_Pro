Работа с ZFS

Откатим ядро, установленное на первом занятии.
```bash
sergey@linux-prof:~$ uname -r
6.8.0-110-generic
```
Установим zfsutils
```bash
root@linux-prof:~# apt update && apt install linux-headers-$(uname -r) dkms zfsutils-linux zfs-dkms
```
Создадим zfs pool в Mirror
```bash
root@linux-prof:~# zpool create zfs_test mirror /dev/sdc /dev/sde
root@linux-prof:~# zpool list
NAME       SIZE  ALLOC   FREE  CKPOINT  EXPANDSZ   FRAG    CAP  DEDUP    HEALTH  ALTROOT
zfs_test  9.50G   111K  9.50G        -         -     0%     0%  1.00x    ONLINE  -
```
Создадим 4 файловых системы.
```bash
root@linux-prof:~# zfs create zfs_test/zfs1
root@linux-prof:~# zfs create zfs_test/zfs2
root@linux-prof:~# zfs create zfs_test/zfs3
root@linux-prof:~# zfs create zfs_test/zfs4
root@linux-prof:~# zfs get mountpoint
NAME           PROPERTY    VALUE           SOURCE
zfs_test       mountpoint  /zfs_test       default
zfs_test/zfs1  mountpoint  /zfs_test/zfs1  default
zfs_test/zfs2  mountpoint  /zfs_test/zfs2  default
zfs_test/zfs3  mountpoint  /zfs_test/zfs3  default
zfs_test/zfs4  mountpoint  /zfs_test/zfs4  default
```
Настроим на каждой разный тип сжатия
```bash
root@linux-prof:~# zfs set compression=lzjb zfs_test/zfs1
root@linux-prof:~# zfs set compression=lz4 zfs_test/zfs2
root@linux-prof:~# zfs set compression=gzip-9 zfs_test/zfs3
root@linux-prof:~# zfs set compression=zle zfs_test/zfs4
root@linux-prof:~# zfs get compression
NAME           PROPERTY     VALUE           SOURCE
zfs_test       compression  on              default
zfs_test/zfs1  compression  lzjb            local
zfs_test/zfs2  compression  lz4             local
zfs_test/zfs3  compression  gzip-9          local
zfs_test/zfs4  compression  zle             local
```
Скопируем в каждую фс файлы
```bash
root@linux-prof:~# cp -r /var/log/* /zfs_test/zfs1/
root@linux-prof:~# cp -r /var/log/* /zfs_test/zfs2/
root@linux-prof:~# cp -r /var/log/* /zfs_test/zfs3/
root@linux-prof:~# cp -r /var/log/* /zfs_test/zfs4/
```
Посмотрим степень сжатия
```bash
root@linux-prof:~# zfs get all | grep compressratio | grep -v ref
zfs_test       compressratio         10.07x                 -
zfs_test/zfs1  compressratio         8.64x                  -
zfs_test/zfs2  compressratio         13.89x                 -
zfs_test/zfs3  compressratio         21.59x                 -
zfs_test/zfs4  compressratio         6.15x                  -
```
gzip-9 самый эффективный по сжатию, но самый медленный на запись

Определим настройки пула
```bash
root@linux-prof:~# zpool status
  pool: zfs_test
 state: ONLINE
config:

        NAME        STATE     READ WRITE CKSUM
        zfs_test    ONLINE       0     0     0
          mirror-0  ONLINE       0     0     0
            sdc     ONLINE       0     0     0
            sde     ONLINE       0     0     0

errors: No known data errors
root@linux-prof:~# zfs get available zfs_test
NAME      PROPERTY   VALUE  SOURCE
zfs_test  available  9.15G  -
root@linux-prof:~# zfs get recordsize zfs_test
NAME      PROPERTY    VALUE    SOURCE
zfs_test  recordsize  128K     default
root@linux-prof:~# zfs get compression zfs_test
NAME      PROPERTY     VALUE           SOURCE
zfs_test  compression  on              default
root@linux-prof:~# zfs get compression
NAME           PROPERTY     VALUE           SOURCE
zfs_test       compression  on              default
zfs_test/zfs1  compression  lzjb            local
zfs_test/zfs2  compression  lz4             local
zfs_test/zfs3  compression  gzip-9          local
zfs_test/zfs4  compression  zle             local
root@linux-prof:~# zfs get checksum zfs_test
NAME      PROPERTY  VALUE      SOURCE
zfs_test  checksum  on         default
```
Скачаем файл
```bash
root@linux-prof:~# wget -O otus_task2.file --no-check-certificate https://drive.usercontent.google.com/download?id=1wgxjih8YZ-cqLqaZVa0lA3h3Y029c3oI&export=download
```
Восстановим файловую систему из снапшота
```bash
root@linux-prof:~# zfs receive zfs_test/zfs5@today < otus_task2.file
```
Найдём файл
```bash
root@linux-prof:~# find /zfs_test/zfs5 -name "secret_message"
/zfs_test/zfs5/task1/file_mess/secret_message
```
Посмотрим содержимое
```bash
root@linux-prof:~# cat /zfs_test/zfs5/task1/file_mess/secret_message
https://otus.ru/lessons/linux-hl/
```







