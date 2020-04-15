# cryptomnesia

Linux deniable cryptographic storage eraser based on hardware USB trigger for self-destruction in a case of emergency

(hard to find an acronym for that one huh?)

![](https://github.com/cryptolok/cryptomnesia/raw/master/logo.png)

![(https://img.youtube.com/vi/eTOwVK--qHo/0.jpg)](https://youtu.be/eTOwVK--qHo)

Dependencies:
* **LUKS** - Linux Unified Key Setup, widely used nowadays for disk encryption
	- cryptsetup - its main CLI, works both for version 1 and 2
* **DigiSpark** - a cheap piece of hardware for USB simulation, used as a trigger
	- Arduino IDE and AVRDUDE - used to upload the code
	- AVR ISP programmer with SOIC8 clips and micronucleus, plus some jumper wires - optional, allows firmware reprogramming to achieve significantly faster USB detection
* **root shell** - the whole script with some basic commands (dd, fdisk, df, sync, lsusb, update-grub)

## Intro and Insights

OK, I think that everyone felt a little pressure from government in the beginning of 2020 for [obvious reasons](https://en.wikipedia.org/wiki/2019%E2%80%9320_coronavirus_pandemic). Now, I'm not saying that cyberpunk dystopia is right here (even if I think so), but that we have to be ready for it. You might say "no worries dude, I'm a 1337 h4x0r, I use full disk crypto and staff, my data is 144% safe" and you will be right... almost. You see, although, disk encryption protects your data from theft and the password may be difficult to crack, you're still human that can gently give the key if asked "nicely". And I'm not just speaking about [rubber-hose cryptanalysis](https://imgs.xkcd.com/comics/security.png), but there are actual [laws](https://en.wikipedia.org/wiki/Key_disclosure_law) that force you to give the key (or any decryption meaning) if needed in almost any "civilized" country (unless they are busy stealing toilet paper or face masks from each other).

So, what can you do in a scenario where SWAT or Russian mafia breaks into your door? Well, you will probably will not have enough time to run "rm" or "dd" command (considering the fact that some deleted data can still be [recovered](https://en.wikipedia.org/wiki/Data_recovery)) and just powering off the PC will still leave you as a key/password holder. You can always destroy the PC or the disk itself (or even a dedicated device to encrypt or/and hold keys), but you can't be sure that the damage will be sufficient (unless you use EMP or something). Of course, if you're using [deniable encryption](https://security.stackexchange.com/questions/87153/linux-plausibly-deniable-file-system) or [steganographic storage](https://cryptolok.blogspot.com/2017/12/skyrimcrypt-deniable-encryption-and.html) already, then you just swaped one problem for another, but I won't talk about those solutions since they are quite separate topics. Thus, the poor-man's solution is just to soft self-destruct, to erase the keys, to make the encrypted storage undecryptable and unreadable even by your-self, once and for all, irreversibly. Sounds pretty scary and challenging, I know, but let's look at technical details right now.

(yeah, that was kind of a rant blog, but anyway)

Basically, when a PC is powered up, the BIOS will check if everything is OK and if there is a disk to boot. If it's the case it will search for a bootable code that contains partitions (like MBR or GPT) and passes the control to it. If there is a partition containing a bootloader (like GRUB) it will pass the control to it next. The bootloader will search for a kernel (vmlinuz) and a file system (initrd) to boot, then it will load the rest of your files and data, hence the whole system is booted and you have your shell (or KDE environment). The whole process is a bit more complicated (like shadow memory, inithooks, etc), but it will be enough to understand the rest. Now, if your disk is encrypted (using LUKS for instance), it's actually isn't encrypted completely, the MBR/GPT and bootloader are still [stored in clear](https://viktorbarzin.me/images/11-booting-into-trouble-1-22-53-54.png) (which is a [HUGE](https://en.wikipedia.org/wiki/Evil_maid_attack) security issue, but that's another problem), otherwise the PC won't boot. Moreover, the disk even isn't encrypted with your password, it's encrypted with a randomly generated key that is stored encrypted with your password in a pretty [descent way](https://irq5.files.wordpress.com/2014/11/luks-encryption-flowchart.png?w=640&h=211). So, when you enter your password, it decrypts the key which goes to memory and [stays there](http://i.stack.imgur.com/KuoSQ.png) to encrypt and decrypt the data from and to your disk on the fly. Such system [isn't perfect](https://en.wikipedia.org/wiki/Cold_boot_attack) and has its own [flaws](https://github.com/cryptolok/AES-REX), but again, we're dealing with a different issue here. Another important thing to mention is that all this metadata (ciphers, hashes, etc) and additional passphrases are stored in a specific location on the encrypted partition, called [header](https://i.stack.imgur.com/CYUGV.png).

(I actually considered making a blog about it, but since there are plenty of info already on this topic, I just decided to make an overview)

Now, the question is, how we can erase our data quickly and certainly? Well, first of all, why to erase all of it if we can just erase the key since it's needed for decryption? That could be done with just one command, but that will still leave the whole header, proving that your disk was indeed encrypted (and prompting for password at boot), which could cause you some (even more) troubles. Thus, it is better to erase (or even write random data to) the whole header, in order for the partition to look like empty or corrupted. But even so, you still have your bootloader and everything else showing that you at least have an operational disk (or had sda2_crypt partition in /boot/grub/menu.lst, that also has to be replaced if not using LVM), so why not to delete (or randomly overwrite) it all, making it look like a complete rubbish? Well, it's a good idea at first sight, but your boot partition could be pretty big (especially if using LVM/RAID) and you may not have SSD but HDD, which will perform write operation much slower. At the same time, if you can just trigger the event and launch it in the background with fewer possibilities to cancel it (assuming the attacker will not instantly perform cold-boot), that would work. However, even if we delete the key from the storage, it is still in the live memory, so we have to instantly power off the PC just after erasing the key, which will empty our memory and make the key unrecoverable (or at least difficult to recover, especially with DDR3L or DDR4 RAMs nowadays). If you have a laptop, don't worry, there is a Linux command to do it (yes, it's basically like cutting power cord, even quicker than pressing the power button), but I mean, it's pretty much like a rule 34 for Linux, if it's possible there is a shell command for it, if not start coding.

Alright, jokes aside, we still have to resolve one more issue, and that's how you're  going to trigger such event. You can simply assign a keyboard shortcut for it, but you may forget it or accidentally type it. Another solution is to make an alias or just double click the script, but still, you will have to remember what they are and where they are, as well as be careful not to launch them by error. That's why, a hardware USB solution is preferable InMyHackishOpition, unless you don't insert a specific device, nothing bad will (should) happen and in case of an emergency you don't have to think, but to act directly and simply.

Finally, what if you still want your data afterwards? Well, if you just erased the header, you can make a backup of it somewhere to restore it and the same goes to full wipe (booloader and all), as well as having a full backup of your disk is not a bad idea either. You can say that if the attacker know that the backup exist, they will go after it and you will be right, but even if there is no backup, it's unlikely that the attacker will believe it, so you still will have to say that there is no backup regardless of it being true or not and accept all the consequences, but if the data is deleted and you can't recover it, you become useless for the attacker whatsoever and if he/she/it wants the backup, he/she/it can't harm you (or at least won't end).

Anyway, let's conclude this pretty long talk before it gets too geo-political/phylosophical and do some practice, but just before that, few demonstrations:

Quick erase the header with customized hardware:
![(https://img.youtube.com/vi/B8eeKmVKVDw)/0.jpg)]( https://youtu.be/B8eeKmVKVDw)

Full erase the disk with customized hardware or quick erase the header with stock hardware:
![(https://img.youtube.com/vi/JawzFsdEXXc/0.jpg)](https://youtu.be/JawzFsdEXXc)

### HowTo

**!!! WARNING !!!** be very attentive and cautious with this guide and code, one error could cost you all data, so please be careful

First things first, make sure that cryptsetup, dd, fdisk, df, sync, lsusb and update-grub commands are available to you and installed as well as your disk in encrypted with LUKS.

As I mentioned, the solution can be used without any additional hardware, but is intended to, so you will also need a [DigiSpark USB](http://digistump.com/products/1), those are pretty cheap in any online shop.

Now, there are 2 solutions: easy, but slow, and hard, but fast.

**EASY**

1 - Plug your GigiSpark

2 - [Configure](https://digistump.com/wiki/digispark/tutorials/connecting) it using default proposed settings (requires to install Arduino IDE)

3 - Modify (by commenting) lines 256 and 265 in ~/.arduino*/packages/digistump/hardware/avr/*/libraries/DigisparkCDC/usbconfig.h (requires IDE restart):

	Replace "0xd0, 0x16" with "0xad, 0xde"

	Replace "0x7e, 0x08" with "0xd", 0xc0"

The first one is simulated USB vendor ID in little-endian, which is "0xdead"

The second one is simulated USB device ID in little-endian, which is "0xc0de"

You may notice that I use CDC library (serial) and not the default USB library, mainly because it's more easy and quick
	
4 - Open [my code](https://github.com/cryptolok/cryptomnesia/blob/master/deadc0de.ino) with IDE

5 - Compile and upload

6 - When typing "lsusb" you should see something like "Bus 001 Device 003: ID dead:c0de" after about 7-10 seconds plugging the device

The "dead:c0de" is the trigger USB device code used by the scripts. You can (and even should) replace it by your own code and don't forget to restore usbconfig.h with its original values. The total number of possibilities for the whole ID is (2^8)^4 = over 4 billion possibilities to bruteforce, if you chose it randomly, it is strongly advised that you change it though, which will prevent someone pluggging the same device to your computer without your permission, optionally, you can even use your own USB device.

As you can see, this is pretty easy setup, but you will have to wait a little bit before the USB code is changed and thus triggered, so just to delete the header you will have to wait about 10s without unplugging the USB and even more if you wish to erase bootloader (may even take up to a minute depending on your setup).

**HARD** (requires some electronics tools and skills)

1 - Plug an AVR ISP USB programmer (any USBasp, those are easily found online)

2 - Connect SOIC8 clip (also found online) on DigiSpark chip (SOP8 Attiny85) and its pins to your programmer using jumper wires

3 - Set the fuses and upload modified [firmware](https://github.com/cryptolok/cryptomnesia/blob/master/deadc0de.hex):

```bash
sudo apt-get install avrdude
avrdude -c USBasp -p attiny85 -U lfuse:w:0xe1:m -U hfuse:w:0xdd:m -U efuse:w:0xfe:m -B 20
avrdude -c USBasp -p attiny85  -U flash:w:deadc0de.hex:i -B 20
```

4 - When typing "lsusb" you should see something like "Bus 001 Device 003: ID dead:c0de" almost immediately after plugging the device

As an alternative to SOIC pins, you can connect programmer directly to DigiSpark pins, but that would require soldering them in the first place and then desoldering in order to make the device more or less usable, so I'm not considering it as a good option. Instead of jumpers you can directly reconnect pins on SOIC clip.

Check-out my [setup](https://github.com/cryptolok/cryptomnesia/tree/master/setup).

You can see what those fuse values are for and what they do [here](http://www.engbedded.com/fusecalc). You can also adapt them to suit your needs.

If you don't trust my firmware or/and want to modify the USB IDs, you can compile [micronucleus](https://github.com/micronucleus/micronucleus) yourself by modifying associated [file](https://github.com/micronucleus/micronucleus/blob/master/firmware/usbconfig.h#L209), or you can also reverse it if you want.

As you can see, it's not that easy to do on your own, but the advantage is that the USB ID recognition is almost instant and deleting just the header will take few seconds. Deleting the bootloader will take some time, but you can just plug the USB to activate the task which can be run in background and then the PC will automatically shutdown, so it's also a realistic usage.

Nonetheless, if you really need a reprogrammed DigiSpark USB with a custom ID, you can just ask me to send you one (not for free of course).

**CONFIG**

OK, the software part is pretty straight forward.

There is a [quick version](https://github.com/cryptolok/cryptomnesia/blob/master/cryptomnesia.sh) of wipe, so just the header will be erased and /boot/grub/menu.lst file will be overwritten to hide the presence of encrypted partition (if not using LVM).

There is is a [full version](https://github.com/cryptolok/cryptomnesia/blob/master/cryptomnesiaFull.sh), thus deleting MBR/GPT, bootloader and the header. However, this could make much time, at least 5s, based on your /boot size and disk speed (~10 MB/s for SSD and much slower for HDD), thus it's not a bad idea to just go after the encryption keys and metadata, to make the partition unencryptable, since the real key is password protected and stored encrypted itself on the disk (LUKS header), but you can also shrink your /boot partition to it's actual size (about 50-100 MB) to win some time. Anyway, count at least 5-10s in best case to do everything.

You can launch the script with autostart or crontab (as root), so it will be launched at boot and monitor for a given USB ID (deadc0de by default, but you can modify it).

Note that notification of launch is optional, I didn't implement it in the code, but you can easily add it if you wish (like a buzz or a popup or maybe you want it to be stealthy, it's up to you). One may say it's better to know what's happening, but maybe you don't want anyone to know what's happening at all. Ideally, you can just use multiple devices, one for stealth and quick execution and another one with fancy skull ASCII art and 8-bit synthwave, it depends on what you want and not for me to decide.

Also, read both scripts, they are pretty self-explanatory, small and well commented.

At the same time, I made a killswitch in the beginning to exit the script, just in case you will launch them in YOLO mode, so you will have to remove that line as well.

Lastly, before doing anything, please make sure that you understand what you are doing, make some tests with half of code and make some backups beforehead.

#### Notes

[Cryptomnesia](https://en.wikipedia.org/wiki/Cryptomnesia) is actually a known memory dysfunction.

The name was also partially inspired by an upcoming [game](https://store.steampowered.com/app/999220/Amnesia_Rebirth/).

Theoretically, same thing can be done for mobiles, but in practice it's not that easy and requires too much things to be done correctly. So it's a subject for further research.

Please feel free to contribute and make tests.

This solution alone will not solve all your problems, but may prevent from having others.

Security and freedom have to coexist and not to be privileged one over another.

Cypherpunks don't fight, they don't cry, they write code.

> "A nation that forgets its past can function no better than an individual with amnesia."

David McCullough

