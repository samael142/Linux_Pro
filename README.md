Просмотрим список блочных устройств
```bash
sergey@linux-prof:~$ lsblk
NAME                 MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
sda                    8:0    0   20G  0 disk
├─sda1                 8:1    0    1M  0 part
├─sda2                 8:2    0  1.8G  0 part /boot
└─sda3                 8:3    0 18.2G  0 part
  └─ubuntu--vg-lv--0 252:0    0 18.2G  0 lvm  /
sdb                    8:16   0    2G  0 disk
sdc                    8:32   0    2G  0 disk
```
Будем создавать raid1 Из дисков sdb и sdc
```bash
root@linux-prof:~# mdadm --create --verbose /dev/md1 -l 1 -n 2 /dev/sdb /dev/sdc
```
Проверим, что raid создался
```bash
root@linux-prof:~# cat /proc/mdstat
Personalities : [raid0] [raid1] [raid4] [raid5] [raid6] [raid10] [linear]
md1 : active raid1 sdc[1] sdb[0]
      2094080 blocks super 1.2 [2/2] [UU]

root@linux-prof:~# mdadm -D /dev/md1
/dev/md1:
           Version : 1.2
     Creation Time : Thu Apr 16 07:45:34 2026
        Raid Level : raid1
        Array Size : 2094080 (2045.00 MiB 2144.34 MB)
     Used Dev Size : 2094080 (2045.00 MiB 2144.34 MB)
      Raid Devices : 2
     Total Devices : 2
       Persistence : Superblock is persistent

       Update Time : Thu Apr 16 07:45:51 2026
             State : clean
    Active Devices : 2
   Working Devices : 2
    Failed Devices : 0
     Spare Devices : 0

Consistency Policy : resync

              Name : linux-prof:1  (local to host linux-prof)
              UUID : 0fe99c6d:cbcae89b:f25df9df:3b375ad1
            Events : 17

    Number   Major   Minor   RaidDevice State
       0       8       16        0      active sync   /dev/sdb
       1       8       32        1      active sync   /dev/sdc
```
Поломаем массив. Удалю один из дисков в гипервизоре.
Массив перешёл в состояние Inactive и изменилось название на md127.
```bash
sergey@linux-prof:~$ cat /proc/mdstat
Personalities : [raid0] [raid1] [raid4] [raid5] [raid6] [raid10] [linear]
md127 : inactive sdb[0](S)
      2094080 blocks super 1.2
```
Запустил массив с одним диском:
```bash
root@linux-prof:~# sudo mdadm --stop /dev/md127
mdadm: stopped /dev/md127
root@linux-prof:~# sudo mdadm --assemble --force --run /dev/md1 /dev/sdb
mdadm: /dev/md1 has been started with 1 drive (out of 2).
root@linux-prof:~# cat /proc/mdstat
Personalities : [raid0] [raid1] [raid4] [raid5] [raid6] [raid10] [linear]
md1 : active raid1 sdb[0]
      2094080 blocks super 1.2 [2/1] [U_]

unused devices: <none>
root@linux-prof:~# mdadm -D /dev/md1
/dev/md1:
           Version : 1.2
     Creation Time : Thu Apr 16 07:45:34 2026
        Raid Level : raid1
        Array Size : 2094080 (2045.00 MiB 2144.34 MB)
     Used Dev Size : 2094080 (2045.00 MiB 2144.34 MB)
      Raid Devices : 2
     Total Devices : 1
       Persistence : Superblock is persistent

       Update Time : Thu Apr 16 07:45:51 2026
             State : clean, degraded
    Active Devices : 1
   Working Devices : 1
    Failed Devices : 0
     Spare Devices : 0

Consistency Policy : resync

              Name : linux-prof:1  (local to host linux-prof)
              UUID : 0fe99c6d:cbcae89b:f25df9df:3b375ad1
            Events : 17

    Number   Major   Minor   RaidDevice State
       0       8       16        0      active sync   /dev/sdb
       -       0        0        1      removed
```
Опять выключаем ВМ и добавляем новый диск.
```bash
root@linux-prof:~# lsblk
NAME                 MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
sda                    8:0    0   20G  0 disk
├─sda1                 8:1    0    1M  0 part
├─sda2                 8:2    0  1.8G  0 part /boot
└─sda3                 8:3    0 18.2G  0 part
  └─ubuntu--vg-lv--0 252:0    0 18.2G  0 lvm  /
sdb                    8:16   0    2G  0 disk
└─md127                9:127  0    0B  0 md
sdc                    8:32   0    2G  0 disk
```
И ремонтируем RAID
```bash
root@linux-prof:~# mdadm  /dev/md1 --add /dev/sdc
mdadm: added /dev/sdc
```
Проверяем, что всё собралось:
```bash
root@linux-prof:~# cat /proc/mdstat
Personalities : [raid0] [raid1] [raid4] [raid5] [raid6] [raid10] [linear]
md1 : active raid1 sdc[2] sdb[0]
      2094080 blocks super 1.2 [2/2] [UU]

unused devices: <none>
root@linux-prof:~# mdadm -D /dev/md1
/dev/md1:
           Version : 1.2
     Creation Time : Thu Apr 16 07:45:34 2026
        Raid Level : raid1
        Array Size : 2094080 (2045.00 MiB 2144.34 MB)
     Used Dev Size : 2094080 (2045.00 MiB 2144.34 MB)
      Raid Devices : 2
     Total Devices : 2
       Persistence : Superblock is persistent

       Update Time : Thu Apr 16 08:16:16 2026
             State : clean
    Active Devices : 2
   Working Devices : 2
    Failed Devices : 0
     Spare Devices : 0

Consistency Policy : resync

              Name : linux-prof:1  (local to host linux-prof)
              UUID : 0fe99c6d:cbcae89b:f25df9df:3b375ad1
            Events : 36

    Number   Major   Minor   RaidDevice State
       0       8       16        0      active sync   /dev/sdb
       2       8       32        1      active sync   /dev/sdc

```
Создаем раздел GPT
```bash
root@linux-prof:~# parted -s /dev/md1 mklabel gpt
```
Создадим 5 разделов и файловую систему на них
```bash
root@linux-prof:~# parted /dev/md1 mkpart primary ext4 1MB 101MB
root@linux-prof:~# parted /dev/md1 mkpart primary ext4 101MB 201MB
root@linux-prof:~# parted /dev/md1 mkpart primary ext4 201MB 301MB
root@linux-prof:~# parted /dev/md1 mkpart primary ext4 301MB 401MB
root@linux-prof:~# parted /dev/md1 mkpart primary ext4 401MB 501MB
root@linux-prof:~# for i in $(seq 1 5); do sudo mkfs.ext4 /dev/md1p$i; done
```
Создадим точку монтирования и смонтируем разделы
```bash
root@linux-prof:~# kdir -p /mnt/part{1,2,3,4,5}
root@linux-prof:~# or i in $(seq 1 5); do mount /dev/md1p$i /mnt/part$i; done
```
Проверим:
```bash
root@linux-prof:~# df -h
Filesystem                    Size  Used Avail Use% Mounted on
tmpfs                         197M 1004K  196M   1% /run
/dev/mapper/ubuntu--vg-lv--0   18G  5.6G   12G  34% /
tmpfs                         982M     0  982M   0% /dev/shm
tmpfs                         5.0M     0  5.0M   0% /run/lock
/dev/sda2                     1.8G  313M  1.3G  20% /boot
tmpfs                         197M   12K  197M   1% /run/user/1000
/dev/md1p1                     86M   24K   79M   1% /mnt/part1
/dev/md1p2                     86M   24K   80M   1% /mnt/part2
/dev/md1p3                     86M   24K   79M   1% /mnt/part3
/dev/md1p4                     86M   24K   79M   1% /mnt/part4
/dev/md1p5                     86M   24K   80M   1% /mnt/part5
```
Пропишем в ftab
```bash
/dev/md1p1  /mnt/part1  ext4  defaults  0  0
/dev/md1p2  /mnt/part2  ext4  defaults  0  0
/dev/md1p3  /mnt/part3  ext4  defaults  0  0
/dev/md1p4  /mnt/part4  ext4  defaults  0  0
/dev/md1p5  /mnt/part5  ext4  defaults  0  0
```
