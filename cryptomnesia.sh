#!/bin/bash

# KILLSWITCH prevents from accidental execution, please remove this code in order to use the script
exit

ID="dead:c0de"
# USB vendor_id:device_id that should be replaced

DEVICE=/dev/$(ls /dev/mapper | grep crypt | cut -d '_' -f 1)
# this is (suppose to be) your encrypted LUKS partition, usually sda2 or vda5 (LVM), please check if it's the case
DISK=$(echo -n ${DEVICE##*/} | head -c -1)
SIZE=$(cat /sys/block/$DISK/queue/logical_block_size)
# logical (used by the kernel) storage block size, usually 512 bytes
OFFSET=$(cryptsetup luksDump $DEVICE | grep Payload | cut -d ':' -f 2 | tr -d ' \t')
# LUKS header offset (before encrypted data), usually 4096 blocks, although the actual data is smaller in size (1 MB for LUKSv1 (the rest isn't used, but marked as reserved) and 2 MB for LUKSv2), this is the total length of the header
BOOTLOADER=/boot/grub/menu.lst
# this is the default boot list for GRUB 2 (non-LVM)
CRYPT=/dev/mapper/$(ls /dev/mapper | grep crypt)
# typical location of an encrypted partition
# all these values are determined automatically, but it is recommended to check them manually or even specify depending on your particular case

while true
do
	lsusb -d "$ID" >/dev/null
# compatible with my USBlock solution (https://github.com/cryptolok/USBlok)
	if [[ $? -eq 0 ]]
	then
# TODO add a notifier, maybe an 8-bit sound, maybe a blink, or a skull ASCII art
		if [[ -f "$BOOTLOADER" ]]
		then
			sed -i s:$CRYPT:$DEVICE:g $BOOTLOADER
			update-grub
		fi
# hide the fact that the bootloader was used for an encrypted partition, this will make the encrypted partition to look like a simple one (non-LVM)
		dd if=/dev/urandom of=$DEVICE bs=$SIZE count=$OFFSET
# this will put pseudo-random data (secure and fast enough) to the LUKS header entirely (and not just the key, about 2 MB), making the partition look like it's corrupted or broken and contains nothing (except some entropic data that can be anything)
#		echo 'YES' | cryptsetup luksErase $DEVICE - this will only erase the keys, but not the header
		sync
# flushing data to disk is necessary, since performing a hard poweroff just after and in order to be sure of change
		echo o > /proc/sysrq-trigger
#		systemctl --force --force poweroff
# this will immediately shutdown the PC, losing all data
	fi
	sleep 1
done

