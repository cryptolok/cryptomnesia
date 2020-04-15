#!/bin/bash

# KILLSWITCH prevents from accidental execution, please remove this code in order to use the script
exit

ID="dead:c0de"
# USB vendor_id:device_id that should be replaced

DISK=$(ls /dev/mapper | grep crypt | cut -d '_' -f 1 | head -c -2)
DEVICE=/dev/$DISK
# this is (suppose to be) your disk, usually sda or vda (LVM), please check if it's the case
BLOCKS=$(cat /sys/block/$DISK/queue/logical_block_size)
# logical (used by the kernel) storage block size, usually 512 bytes
START=$(fdisk -l $DEVICE | grep -A1 Start | tr -s ' ' | cut -d ' ' -f 3 | tail -n 1)
# these are the first bytes of your disk, usually containing partition table (MBR/GPT alike) of 1 MB
PARTS=$[$BLOCKS*$START/2**10/2**10]
LOADER=$(df /boot | cut -d ' ' -f 1 | tail -n 1)
SECTORS=$(fdisk -l $LOADER | grep sectors | cut -d ',' -f 3 | cut -d ' ' -f 2 | head -n 1)
# this is your /boot partition (bootloader, like GRUB), usually 50-100 MB of used size, but the partition itself could be larger (up to 1 GB), so you can shrink it to its actual size to win some time
BOOT=$[$BLOCKS*$SECTORS/2**10/2**10]
CRYPT=/dev/$(ls /dev/mapper | grep crypt | cut -d '_' -f 1)
# this is (suppose to be) your encrypted LUKS partition, usually sda2 or vda5 (LVM), please check if it's the case
OFFSET=$(cryptsetup luksDump $CRYPT | grep Payload | cut -d ':' -f 2 | tr -d ' \t')
# LUKS header offset (before encrypted data), usually 4096 blocks, although the actual data is smaller in size (1 MB for LUKSv1 (the rest isn't used, but marked as reserved) and 2 MB for LUKSv2), this is the total length of the header
HEADER=$[$BLOCKS*$OFFSET/2**10/2**10]
SIZE=$[$PARTS+$BOOT+$HEADER]
# the total size would be at least 50 MB, assuming you don't have multiple disks or other encrypted partitions
# for LVM, there will be an additional partition (like sda2p1) for about 1 KB, so the script will not write the same size at the end of LUKS header, but since we calculate its whole offset and not just the data containing inside, this error is tolerable and should not impact the keys within the header, but if in doubt, you can adjust everything you need by yourself
# all these values are determined automatically, but it is recommended to check them manually or even specify depending on your particular case

while true
do
	lsusb -d "$ID" >/dev/null
# compatible with my USBlock solution (https://github.com/cryptolok/USBlok)
	if [[ $? -eq 0 ]]
	then
# TODO add a notifier, maybe an 8-bit sound, maybe a blink, or a skull ASCII art
		dd if=/dev/urandom of=$DEVICE bs=1M count=$SIZE
# this will put pseudo-random data (secure and fast enough) to the LUKS header entirely (and not just the key), plus the bootloader (/boot) and MBR/GPT partitions table, making the whole disk look like it's corrupted or broken and contains nothing (except some entropic data that can be anything)
		sync
# flushing data to disk is necessary, since performing a hard poweroff just after and in order to be sure of change
		echo o > /proc/sysrq-trigger
#		systemctl --force --force poweroff
# this will immediately shutdown the PC, losing all data
	fi
	sleep 1
done

