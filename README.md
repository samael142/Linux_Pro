Работа с LVM.

Добавим дисков в виртуальную машину
```bash
root@linux-prof:~# lsblk
NAME                 MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
sda                    8:0    0   20G  0 disk
├─sda1                 8:1    0    1M  0 part
├─sda2                 8:2    0  1.8G  0 part /boot
└─sda3                 8:3    0 18.2G  0 part
  └─ubuntu--vg-lv--0 252:0    0 18.2G  0 lvm  /
sdb                    8:16   0    2G  0 disk
sdc                    8:32   0   10G  0 disk
sdd                    8:48   0    2G  0 disk
sde                    8:64   0   10G  0 disk
```
Будем уменьшать том под / до 8G
```bash
Проверим свободное и занятое место
root@linux-prof:~# df -h /
Filesystem                    Size  Used Avail Use% Mounted on
/dev/mapper/ubuntu--vg-lv--0   18G  6.0G   11G  36% /
```
Загрузимся с LiveCD И будем делать там:
<img width="1165" height="944" alt="lvreduce" src="https://github.com/user-attachments/assets/2aa31482-a717-4785-b383-6ebc1f9db114" />
Проверим:
```bash
root@linux-prof:~# lsblk
NAME                 MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
sda                    8:0    0   20G  0 disk
├─sda1                 8:1    0    1M  0 part
├─sda2                 8:2    0  1.8G  0 part /boot
└─sda3                 8:3    0 18.2G  0 part
  └─ubuntu--vg-lv--0 252:0    0    8G  0 lvm  /
sdb                    8:16   0    2G  0 disk
sdc                    8:32   0   10G  0 disk
sdd                    8:48   0    2G  0 disk
sde                    8:64   0   10G  0 disk
sr0                   11:0    1 1024M  0 rom
```
Разметим sdc, создадим PV:
```bash
root@linux-prof:~# pvcreate /dev/sdc
  Physical volume "/dev/sdc" successfully created.
```
Сделаем VG
```bash
root@linux-prof:~# vgcreate big-10 /dev/sdc
  Volume group "big-10" successfully created
```
И создадим и разметим LV:
```bash
root@linux-prof:~# lvcreate -L1G -n home
big-10     ubuntu-vg
root@linux-prof:~# lvcreate -L1G -n home big-10
  Logical volume "home" created.
root@linux-prof:~# mkfs.ext4 /dev/big-10/home
mke2fs 1.47.0 (5-Feb-2023)
Discarding device blocks: done
Creating filesystem with 262144 4k blocks and 65536 inodes
Filesystem UUID: 35a8bc86-30f2-4c76-ace2-38c640b0b215
Superblock backups stored on blocks:
        32768, 98304, 163840, 229376

Allocating group tables: done
Writing inode tables: done
Creating journal (8192 blocks): done
Writing superblocks and filesystem accounting information: done
```
Выделим созданный LV под /home
```bash
root@linux-prof:~# mount /dev/big-10/home /mnt/
root@linux-prof:~# cp -aR /home/* /mnt/
root@linux-prof:~# rm -rf /home/*
root@linux-prof:~# umount /mnt
root@linux-prof:~# mount /dev/big-10/home /home/
root@linux-prof:~# ls -la /home/
total 28
drwxr-xr-x  4 root   root    4096 Apr 27 09:15 .
drwxr-xr-x 23 root   root    4096 Apr 27 07:12 ..
drwx------  2 root   root   16384 Apr 27 09:10 lost+found
drwxr-x---  5 sergey sergey  4096 Apr 27 07:12 sergey
```
Узнаем UUID И пропишем монтирование в fstab
```bash
root@linux-prof:~# blkid /dev/big-10/home
/dev/big-10/home: UUID="35a8bc86-30f2-4c76-ace2-38c640b0b215" BLOCK_SIZE="4096" TYPE="ext4"

UUID=35a8bc86-30f2-4c76-ace2-38c640b0b215  /home  ext4  defaults  0  2

root@linux-prof:~# umount /home
root@linux-prof:~# mount -a
root@linux-prof:~# ls -la /home/
total 28
drwxr-xr-x  4 root   root    4096 Apr 27 09:15 .
drwxr-xr-x 23 root   root    4096 Apr 27 07:12 ..
drwx------  2 root   root   16384 Apr 27 09:10 lost+found
drwxr-x---  5 sergey sergey  4096 Apr 27 07:12 sergey
```
Сделаем снапшот /home и примонтируем его
```bash
root@linux-prof:~# lvcreate -L 100MB -s -n home_snapshot /dev/big-10/home
  Logical volume "home_snapshot" created.
root@linux-prof:~# lvs
  LV            VG        Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  home          big-10    owi-aos---   1.00g
  home_snapshot big-10    swi-a-s--- 100.00m      home   0.01
  lv-0          ubuntu-vg -wi-ao----   8.00g
root@linux-prof:~# mkdir /mnt/snap_home
root@linux-prof:~# mount /dev/big-10/home_snapshot /mnt/snap_home
```
Удалим файлы и восстановим:
```bash
root@linux-prof:~# ls -la /home/
total 28
drwxr-xr-x  4 root   root    4096 Apr 27 09:40 .
drwxr-xr-x 23 root   root    4096 Apr 27 07:12 ..
-rw-r--r--  1 root   root       0 Apr 27 09:33 file1
-rw-r--r--  1 root   root       0 Apr 27 09:33 file10
-rw-r--r--  1 root   root       0 Apr 27 09:33 file2
-rw-r--r--  1 root   root       0 Apr 27 09:33 file3
-rw-r--r--  1 root   root       0 Apr 27 09:33 file4
-rw-r--r--  1 root   root       0 Apr 27 09:33 file5
-rw-r--r--  1 root   root       0 Apr 27 09:33 file6
-rw-r--r--  1 root   root       0 Apr 27 09:33 file7
-rw-r--r--  1 root   root       0 Apr 27 09:33 file8
-rw-r--r--  1 root   root       0 Apr 27 09:33 file9
drwx------  2 root   root   16384 Apr 27 09:10 lost+found
drwxr-x---  5 sergey sergey  4096 Apr 27 07:12 sergey
root@linux-prof:~# cp /mnt/snap_home/file{11..20} /home/
root@linux-prof:~# ls -la /home/
total 28
drwxr-xr-x  4 root   root    4096 Apr 27 09:41 .
drwxr-xr-x 23 root   root    4096 Apr 27 07:12 ..
-rw-r--r--  1 root   root       0 Apr 27 09:33 file1
-rw-r--r--  1 root   root       0 Apr 27 09:33 file10
-rw-r--r--  1 root   root       0 Apr 27 09:41 file11
-rw-r--r--  1 root   root       0 Apr 27 09:41 file12
-rw-r--r--  1 root   root       0 Apr 27 09:41 file13
-rw-r--r--  1 root   root       0 Apr 27 09:41 file14
-rw-r--r--  1 root   root       0 Apr 27 09:41 file15
-rw-r--r--  1 root   root       0 Apr 27 09:41 file16
-rw-r--r--  1 root   root       0 Apr 27 09:41 file17
-rw-r--r--  1 root   root       0 Apr 27 09:41 file18
-rw-r--r--  1 root   root       0 Apr 27 09:41 file19
-rw-r--r--  1 root   root       0 Apr 27 09:33 file2
-rw-r--r--  1 root   root       0 Apr 27 09:41 file20
-rw-r--r--  1 root   root       0 Apr 27 09:33 file3
-rw-r--r--  1 root   root       0 Apr 27 09:33 file4
-rw-r--r--  1 root   root       0 Apr 27 09:33 file5
-rw-r--r--  1 root   root       0 Apr 27 09:33 file6
-rw-r--r--  1 root   root       0 Apr 27 09:33 file7
-rw-r--r--  1 root   root       0 Apr 27 09:33 file8
-rw-r--r--  1 root   root       0 Apr 27 09:33 file9
drwx------  2 root   root   16384 Apr 27 09:10 lost+found
drwxr-x---  5 sergey sergey  4096 Apr 27 07:12 sergey
```
Ну или можно через lvconvert --merge

Выделим том под var в Mirror
Будем использовать sdb и sdd
```bash
root@linux-prof:~# vgcreate vg_var /dev/sdb /dev/sdd
  Physical volume "/dev/sdb" successfully created.
  Physical volume "/dev/sdd" successfully created.
  Volume group "vg_var" successfully created
root@linux-prof:~# lvcreate -L 1G -m1 -n lv_var vg_var
  Logical volume "lv_var" created.
root@linux-prof:~# mkfs.ext4 /dev/vg_var/lv_var
mke2fs 1.47.0 (5-Feb-2023)
Discarding device blocks: done
Creating filesystem with 262144 4k blocks and 65536 inodes
Filesystem UUID: 7abfcf01-d1d4-4ae6-9537-05aedd155d24
Superblock backups stored on blocks:
        32768, 98304, 163840, 229376

Allocating group tables: done
Writing inode tables: done
Creating journal (8192 blocks): done
Writing superblocks and filesystem accounting information: done
```
Перенесём, смонтируем и пропишем в fstab
```bash
root@linux-prof:~# mount /dev/vg_var/lv_var /mnt
root@linux-prof:~# cp -aR /var/* /mnt/
root@linux-prof:~# umount /mnt
root@linux-prof:~# mount /dev/vg_var/lv_var /var

root@linux-prof:~# blkid /dev/vg_var/lv_var
/dev/vg_var/lv_var: UUID="7abfcf01-d1d4-4ae6-9537-05aedd155d24" BLOCK_SIZE="4096" TYPE="ext4"


UUID=7abfcf01-d1d4-4ae6-9537-05aedd155d24  /var  ext4  defaults  0  2
```


