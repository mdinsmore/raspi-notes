Steps to cross compile a kernel for the raspberry pi
====================================================

Some instructions on how to cross compile a kernel for the raspberry pi on a ubuntu box

Assumes you have the pi running and available on the network


On Raspberry Pi
---------------

Get rpi-update:
::
    sudo wget https://raw.githubusercontent.com/Hexxeh/rpi-update/master/rpi-update -O /usr/bin/rpi-update

Make it executable
::
    sudo chmod +x /usr/bin/rpi-update

Get git package
::
    sudo apt-get install git-core

Update the firmware on raspi:
::
    rpi-update

Get the kernel config from the server
::
	mkdir ~/kernel
	cd kernel
	sudo zcat /proc/config.gz > .config

On Ubuntu box
-------------

Make sure required packages are installed (sshfs is optional):
::
    sudo apt-get install gcc-arm-linux-gnueabi make git-core ncurses-dev sshfs

Create a directory for raspberry pi kernel compilation and change to it
::
	mkdir ~/raspi
	cd ~/raspi
    
mount the kernel directory on the raspberry pi using sshfs (optional you can copy using scp if your prefer this just makes it easier
::
	mkdir rpi
	sshfs <username on pi>@<hostname of pi>:kernel rpi

Get the latest kernel sources:
::
	git clone https://github.com/raspberrypi/linux

Get the latest Raspberry Pi compiler:
::
	git clone https://github.com/raspberrypi/tools

Set up the environment:
::
	export KERNEL_SRC=~/raspi/linux                                             
	export CCPREFIX=~/raspi/tools/arm-bcm2708/arm-bcm2708-linux-gnueabi/bin/arm-bcm2708-linux-gnueabi-
	export MODULES_TEMP=~/raspi/modules/
	
Change to the linux directory
::
	cd $KERNEL_SRC

Clean the configuration directory:
::
	make mrproper

Copy config from raspberry pi to ubuntu box
::
	cp ~/raspi/rpi/.config .

Prime the kernel with the old configuration by running:
::
	make ARCH=arm CROSS_COMPILE=${CCPREFIX} oldconfig

Modify the kernel either by modifing 
::
	<your favourite editor>  .config

or using the menu
::
	ARCH=arm CROSS_COMPILE=${CCPREFIX} make menuconfig

Build the new kernel using the command:
::
	ARCH=arm CROSS_COMPILE=${CCPREFIX} make

If you have more than one core on your cross compilation machine you can add
::
	-j <num cores + 1>

e.g. for a dual core machine 
::
	ARCH=arm CROSS_COMPILE=${CCPREFIX} make -j3

Assemble the new kernel modules by using:
::
	ARCH=arm CROSS_COMPILE=${CCPREFIX} INSTALL_MOD_PATH=${MODULES_TEMP} make modules_install

Use the imagetool-uncompressed.py program to create an image
::
	cd ~/raspi/tools/mkimage
	./imagetool-uncompressed.py ${KERNEL_SRC}/arch/arm/boot/zImage

Copy the resulting kernel.img to the Raspberry Pi kernel directory
::
	cp kernel.img ~/raspi/rpi
	rm kernel.img

If you prefer you can use the command "mv kernel.img ~/raspi/rpi" and ignore the "preserve ownership" error.

Package up the modules into an archive (this series of commands assumes you are using sshfs to mount the kernel directory on the raspberry pi on the compilation machine if not you'll need to copy the files to the pi using scp or some other method)
::

	cd $MODULES_TEMP/lib
	tar -cvzf ~/raspi/rpi/modules.tar.gz modules 
	tar -cvzf ~/raspi/rpi/firmware.tar.gz firmware 

	

Back on the raspberry pi
------------------------
The ~/kernel directory on the Raspberry Pi should now look like this
::
	pi@mypi ~/kernel $ ls -l 
	 -rw-r--r--  1 pi pi   105770 Mar 12 19:33 .config
	 -rw-r--r--  1 pi pi   258497 Mar 13 09:43 firmware.tar.gz
	 -rw-r--r--  1 pi pi  3996592 Mar 13 10:08 kernel.img
	 -rw-r--r--  1 pi pi 14180461 Mar 13 09:43 modules.tar.gz
 
Save the existing kernel and copy the new kernel to the boot directory
	cd /boot
	cp kernel.img kernel-old.img
	cp ~/kernel/kernel.img .
	
Save the existing modules and firmware and copy the new modules and firmware to their respective directories under /lib
	cd /lib
	tar -cvzf ~/kernel/prev-modules.tar.gz modules
	tar -cvzf ~/kernel/prev-firmware.tar.gz firmware
	tar -xvzf ~/kernel/modules.tar.gz
	tar -xvzf ~/kernel/firmware.tar.gz
	

