---
title: "Windows10 on Archlinux KVM PCI Passthrough"
date: 2018-08-27T11:14:58+02:00
draft: true
---

This is my ongoing guide/notepad about my virtualized gaming machine setup.

Basically I not only want to play games and have Windows running, I was really fascinated by the
options that virtualization offers nowadays.

This is my pet-project that I plan take with me to [LAN parties](https://www.northcon.de/) and play games at home.
I also use it for my base system to play around with virtual machines.
It is powerful enough to host a dedicated gaming VM and a bunch of other virtual machines.

## The project

I have built a VM host based on ArchLinux + KVM, that is capable of reliably dedicating hardware (Cores, RAM, PCI and USB)
to selected VMs.

It allows me running different systems, including a Windows 10 gaming VM, with unnoticable performance degredation.
All on top of fully encrypted disks in a RAID-1, LVM supported and NVMe SSD cached configuration.

Of course, none of this is necessary if you just want a PC that is capable of playing games.
But for me, the little extra excursion really made a great project to play around with, and will serve
me as a great base for future explorations of the virtualized space.

## Linux Distribution Discussion

ArchLinux vs. Debian was one of the first quesions I answered for myself before starting this project.
I personally like Debian a lot. It is one of the best Linux distributions out there, and I like their
very conservative approach on releases.

But on the other hand, Debian is harder to "mold" into a custom shape than ArchLinux.

And this became my main argument for choosing ArchLinux over Debian. In this project, it has been very helpful
to be able to simply constrain and shape the installation the way I wanted.

This would have been less flexibile, and potentially harder to achieve when using Debian.
If you plan to setup a corporate/commercial installation, I would recommend you go with Debian.
Debian will allow other to contribute much easier, since there are less quirks and custom things to know
about the system than with Arch.

On the other hand, if you plan to fully customize the system, and you plan to completely own and document
that customization, ArchLinux will provide you a good base for that.

## Downloads

Before you get started, start some downloads, so that the ISO images are ready when you need them.

* ArchLinux iso https://mirror.dal10.us.leaseweb.net/archlinux/iso/2018.08.01/
* Windows 10 iso https://www.microsoft.com/de-de/software-download/windows10ISO
* Virtio Windows drivers (stable) https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/archive-virtio/virtio-win-0.1.141-1/

## Hardware (2018)

Here are the main components:

* **Motherboard:** Gigabyte Z370 Aorus Ultra Gaming 2.0

    This is a great motherboard. It supports all features I need, plenty of PCIe, USB 3.0 + C ports, SATA 6Gbps ports.
    Plus the motherboard and Z370 chipset is known to work in Hackintosh setups, another playground for another weekend.
  
* **CPU:** Intel Core i7-8700K, 6x 3.70GHz

    What a beast. 6 cores, that turbo boost beyond 4GHz? What more could I ask for the price (at the time of writing).
    I think it is the best what I could at the time, for the price and features I wanted.
    Most importantly the CPU supports intel VT-d virtualization (iommu).

* **RAM:** G.Skill Trident Z DIMM Kit 32GB, DDR4-3000, CL15-15-15-35

    The Z370 chipset was issued for 2337MHz DDR4 speeds, but this motherboard and the i7-8700K allow for XMP profiles up to 4GHz.
    For the price I found this a great balance between performance and space.
    I think 32GB is the minimum for a virtualized setup that should host a gaming machine.

* **Storage:**

    This is interesting. The Motherboard support M.2 SSDs, which is just amazing.
    The speed you get out of these drives is just insane.
    I backed these with two relatively cheap 3TB drives, that I plan to use in a RAID-1 configuration.

    * **NVMe SSD:** Samsung SSD 970 EVO 1TB, M.2
    * **HDD:** Toshiba DT01ACA 3TB, SATA 6Gb/s (DT01ACA300)

* **Graphics:** Gigabyte GeForce GTX 1060 OC 6G

    Great value for the power you get. Can play all 2018 titles with great quality.

* **Monitor:** ASUS ROG Swift PG258Q, 24.5"

    Now this is a luxury item. But combined with a NVIDIA graphics card, GSync is a bliss.
    I run this monitor at 240Hz refresh rate. You have never seen such a smooth display.
    It had an effect on me, similar when I switched to my first MacBook Pro with retina display.
    For gaming, I think this Monitor + GSync is even more important than having a loud and ultra-beefy GFX card.

* **Peripherals:**

    If you plan to run a dedicated gaming machine, get some great gaming peripherals.
    Not only help secondary peripherals to get around annoying problems when it comes to switching
    inputs to a VM, in a dedicated setup they also perform much better.

    The SteelSeries Rival 600 is probably the best mouse I have played with ever.
    It is silky smooth, has great ergonomics and one outstanding feature: a height sensor.
    When I lift he mouse during gaming, paning around, the **cursor does not jump** and instead I have a 
    smooth rapid movement!

    * **Gaming mouse:** SteelSeries Rival 600
    * **Gaming keyboard:** Cougar 500K US English

* **Case:** Corsair Carbide Series 270R

    A quality case for a very low price with excellent cable management and air flow properties.

* **Cooling:**

    I plan to play around with overclocking my CPU and having a future-safe and quite cooler.
    This radiator setup keeps the whole system at **room temperatures under full load** with almost no effort
    from the fans.

    The Noctua fans are also kind of luxury items. But to be fair, they perform really well at the same time
    you hear nothing. They operate in dead silence.

    * **CPU cooler:** Corsair Hydro H150i PRO RGB 360mm Radiator
    * **Fans:**
      * 4x Noctua NF-F12 PWM 120x120x25mm
      * 2x Noctua NF-A14 ULN 140x140x25mm

* **Power supply:** 650 Watt Seasonic FOCUS Plus Modular 80+ Platinum

    650W are more than enough to power any (future) system. Plus Seasonic proved to be a very quiet,
    high quality PSU with modular cable management. This is really a great plus, if you like clean managable
    hardware installations like me.

I spent € 2600 including a luxury high performance gaming monitor.
The extra money went directly into some high performance plus silence options.

The system itself is valued at around €2000 while delivering quiet rock solid performance.
You can definitely go cheaper than this setup, if you compromise on:

* Silence: Go with an air-cooled CPU and cheaper case fans
* Performance: Buy SATA SSDs instead of a NVMe SSD and get some cheaper RAM

## Additional hardware

I found it most helpful to have an [USB hub + Ethernet adapter](https://amzn.to/2PbqXyJ).
You can delegate such a device directly to the VM and it will provide the VM with dedicated LAN access and an usb hub.

This is particularly helpful if you plan to improve the VM networking performance and you do not want
to setup bridged networking or NAT for your VM.

Have a spare [external USB 3.0 UASP SATA 3 enclosure](https://amzn.to/2wuUfAA) and a [SSD](https://amzn.to/2P9gZxL) available to you.
There is nothing more annoying than waiting forever until your live iso boots from one of these ultra slow
USB sticks. An external SSD elegantly solves this problem.

## BIOS configuration

## Configure and install ArchLinux

* Download the ArchLinux iso, verify checksums and put on an external disk.

        curl -LO https://mirror.dal10.us.leaseweb.net/archlinux/iso/2018.08.01/archlinux-2018.08.01-x86_64.iso
        sha1sum archlinux-*.iso
        dd bs=4000000 if=archlinux-2018.08.01-x86_64.iso of=/dev/disk2

* Connect your external disk and boot into the ArchLinux live system

* The following setup is tailored to my Intel RST RAID-1, fully encrypted, LVM setup with nvme SSD cache

* First live system boot, assemble the Intel RST RAID-1 and create the necessary partitions

        # Check connected block devices
        lsblk

        # Assemble the Intel RST RAID
        mdadm -C /dev/md/imsm --raid-devices=2 --metdata=imsm /dev/sd[ab]
        mdadm -C /dev/md/HDD_0 --raid-devices=2 --level=1 /dev/md/imsm

        # Create partitions
        gdisk /dev/md/HDD_0

        # Use "o" to create GPT table
        # "n" to create partitions:
        # Number  Start (sector)    End (sector)  Size       Code  Name
        #    1            2048         1050623   512.0 MiB   EF00  EFI System
        #    2         1050624         1460223   200.0 MiB   8300  Linux filesystem
        #    3         1460224      1679181823   800.0 GiB   8E00  Linux LVM
        # "w" to write changes
        # "q" to quit

* Full disk encryption setup

        # Create crypted /boot container
        cryptsetup luksFormat /dev/sda2
        cryptsetup open /dev/sda2 cryptboot
        mkfs.ext2 /dev/mapper/cryptboot

        # Create crypted LVM with /root and swap
        cryptsetup luksFormat /dev/sda3
        cryptsetup open /dev/sda3 cryptlvm
        pvcreate /dev/mapper/cryptlvm
        vgcreate vg0 /dev/mapper/cryptlvm
        lvcreate -L 16G vg0 -n swap
        lvcreate -l 100%FREE vg0 -n root
        mkfs.ext4 /dev/mapper/vg0-root
        mkswap /dev/mapper/vg0-swap

        # Check connected block devices
        lsblk

* ArchLinux installation

        # Mount
        swapon /dev/mapper/vg0-swap
        mount /dev/mapper/vg0-root /mnt
        mkdir /mnt/boot
        mount /dev/mapper/cryptboot /mnt/boot
        mkdir /mnt/boot/efi
        mount /dev/sda1 /mnt/boot/efi

        # Check internet connectivity
        ping 1.1.1.1

        # Install system and basic administrative requirements
        pacstrap /mnt base base-devel grub-efi-x86_64 efibootmgr vim git bash tmux dialog wpa_supplicant

        # Generate fstab
        genfstab -pU /mnt >> /mnt/etc/fstab

* Initial system configuration (within live system)

        # Chroot into our newly installed system 
        arch-chroot /mnt

        # Store the RAID configuration
        mdadm --examine --scan >> /etc/mdadm.conf

        # Set timezone, hostname...
        ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime
        hwclock --systohc --utc
        echo archbase > /etc/hostname

        # Configure locales
        echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
        locale-gen
        echo LANG=en_US.UTF-8 > /etc/locale.conf
        echo LANGUAGE=en_US >> /etc/locale.conf
        echo LC_ALL=C >> /etc/locale.conf

        # Set root password
        passwd

* Grub configuration (within chrooted live system)

        # Install grub
        grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=ArchLinux

        # Enable Intel microcode CPU updates (if you use Intel processor, of course)
        pacman -S intel-ucode
        # Regenerate grub.cfg to pick up the intel-ucode changes
        grub-mkconfig -o /boot/grub/grub.cfg

        # Change grub configuration
        #
        # GRUB_ENABLE_CRYPTODISK=y
        # GRUB_CMDLINE_LINUX should contain
        #
        #  cryptdevice=UUID=$(blkid /dev/md/HDD_0p3 -s UUID -o value):lvm resume=/dev/mapper/vg0-swap
        #
        vim /etc/default/grub

        # Regenerate grub.cfg
        # rerun this everytime you change /etc/default/grub
        grub-mkconfig -o /boot/grub/grub.cfg

        # Allow mounting /boot without password request
        dd bs=512 count=8 if=/dev/urandom of=/etc/key
        chmod 400 /etc/key
        cryptsetup luksAddKey /dev/md/HDD_0p2 /etc/key
        echo "cryptboot /dev/md/HDD_0p2 /etc/key luks" >> /etc/crypttab

        # Allow mounting / without password request
        dd bs=512 count=8 if=/dev/urandom of=/crypto_keyfile.bin
        chmod 000 /crypto_keyfile.bin
        cryptsetup luksAddKey /dev/md/HDD_0p3 /crypto_keyfile.bin

        # Add /crypto_keyfile.bin to the FILES array in /etc/mkinitcpio.conf
        vim /etc/mkinitcpio.conf
        # regenerate initramfs, rerun this everytime you change /etc/mkinitcpio.conf
        mkinitcpio -p linux

        # Some additional security
        chmod 700 /boot
        chmod 700 /etc/iptables
        chmod 600 /boot/initramfs-linux*

* First reboot from chrooted live system

        # Exit from chroot, unmount system, shutdown, extract flash stick. You made it! Now you have fully encrypted system.
        exit
        umount -R /mnt
        swapoff -a
        shutdown now

## Configure ArchLinux as a VM host

With PCI passthrough, CPU pinning and Huge pages support.

## Install your Windows VM

The windows installation itself is almost a self-driving process, but make sure you:

* Disable Cortona
* Do not get a Microsoft account
* Install all the virtio drivers right away

## Prepare your Windows VM

Before you go online with your Windows VM here are some helpful guides.

Basically you want to prevent Windows from getting compromised to your best effort,
and you want to prevent Windows and its derivates from being nosey and calling home.

Follow these to guides until you satisfy your personal paranioa level.

* Penetration Testers’ Guide to Windows 10 Privacy & Security https://hackernoon.com/the-2017-pentester-guide-to-windows-10-privacy-security-cf734c510b8d
* Debloat Windows 10 https://github.com/W4RH4WK/Debloat-Windows-10
* Chill out, Windows 10. https://github.com/nichite/chill-out-windows-10
* Block spying and tracking on Windows https://github.com/crazy-max/WindowsSpyBlocker
* Harden Windows 10 - A Security Guide https://www.hardenwindows10forsecurity.com

## Credits

* Install Arch Linux with full disk encryption (including /boot) and UEFI. https://grez911.github.io/cryptoarch.html
* Arch Linux and Intel RST (“Fake RAID”) https://medium.com/@pmarrapese/arch-linux-and-intel-rst-fake-raid-cece10b61ac3
* Adding SSD Cache to Existing LVM https://www.nocser.net/clients/knowledgebase.php?action=displayarticle&id=474&language=english
* PCI passthrough via OVMF https://wiki.archlinux.org/index.php/PCI_passthrough_via_OVMF
* PCI passthrough via OVMF/Examples https://wiki.archlinux.org/index.php/PCI_passthrough_via_OVMF/Examples
* Workaround NVIDIA driver virtualization restrictions https://github.com/sk1080/nvidia-kvm-patcher#alternate-workaround-recent-libvirt--qemu

        <domain>
        ...
            <features>
                ...
                <kvm>
                    <hidden state='on'/>
                </kvm>
                ...
                <hyperv>
                    ...
                    <vendor_id state='on' value='whatever'/>
                </hyperv>
                ...
            </features>
        ...
        </domain>

* Rolling back a device driver [If NVIDIA decides to update its drivers and screws you over, rollback the driver]

    https://support.microsoft.com/en-us/help/3073930/how-to-temporarily-prevent-a-driver-update-from-reinstalling-in-window

* lvcache: a tool for managing LVM caches http://blog.oddbit.com/2014/08/16/lvcache-a-tool-for-managing-lv/
* `man 7 lvmcache` lvmcache (7) - Linux Man Pages https://www.systutorials.com/docs/linux/man/7-lvmcache
* How to resize a Windows VM image with virt-resize https://mike42.me/blog/how-to-resize-a-windows-vm-image-with-virt-resize
* How to install a program from Arch User Repository or AUR https://arashmilani.com/post?id=85
* How to auto-hotplug usb devices to libvirt VMs https://rolandtapken.de/blog/2011-04/how-auto-hotplug-usb-devices-libvirt-vms-update-1
* Script to attach and detach USB devices from libvirt virtual machines based on udev rules. https://github.com/olavmrk/usb-libvirt-hotplug
* Domain XML format https://libvirt.org/formatdomain.html

