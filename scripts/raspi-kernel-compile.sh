#! /bin/bash
# a script to cross compile a raspberry pi kernel on ubuntu, debian or deritive 
# Assumptions:
# * You have a raspberry pi running which is available on your network called "pi-2b"
#   if not change the RASPI_MOUNT_DIRECTORY
# * You access the raspberry pi using the same user name as your cross-compile box
#   if not include the username in the host name e.g. if you are
#   accessing the raspberry pi using the username "pi" you would set 
#   export RASPI_MOUNT_DIRECTORY=pi@pi-2b:kernel

#  Install prequisite packages
echo "Ensuring prequisite packages are installed..."
sudo apt-get install gcc-arm-linux-gnueabi make git-core ncurses-dev sshfs

# configure some environment variables
export RASPI_MOUNT_DIRECTORY=pi-2b:kernel
export RASPI_HOME=$HOME/raspi
export RASPI_MOUNT=$RASPI_HOME/rpi
export RASPI_TOOLS=$RASPI_HOME/tools
export KERNEL_SRC=$RASPI_HOME/linux
export CCPREFIX=$RASPI_TOOLS/arm-bcm2708/arm-bcm2708-linux-gnueabi/bin/arm-bcm2708-linux-gnueabi-
export MODULES_TEMP=$RASPI_HOME/modules/

# Create our working directory (if necessary) and change to it
if [ ! -d $RASPI_HOME ]
then
	echo "Creating working directory $RASPI_HOME"
	mkdir -p $RASPI_HOME
fi

cd $RASPI_HOME

if [ ! -d $RASPI_MOUNT ]
then
	echo "Creating mount point for raspberry pi directory $RASPI_HOME"
	mkdir -p $RASPI_MOUNT
fi

MOUNT_EXISTS=`df -h | grep $RASPI_MOUNT_DIRECTORY`

if [ "$MOUNT_EXISTS" = "" ]
then
	# mount the ~/kernel directory on raspberry pi
	sshfs $RASPI_MOUNT_DIRECTORY $RASPI_MOUNT
fi

# get the latest kernel sources
if [ ! -d $RASPI_HOME/linux/.git ]
then
	cd $RASPI_HOME
	git clone https://github.com/raspberrypi/linux
else
	cd $KERNEL_SRC
	git pull
fi

# get the latest compilation tools
if [ ! -d $RASPI_TOOLS/.git ]
then
	cd $RASPI_HOME
	git clone https://github.com/raspberrypi/tools
else
	cd $RASPI_TOOLS
	git pull
fi

# comile the kernel
cd $KERNEL_SRC

ok=x

while [ "$ok" != "n" -a "$ok" != "N" -a "$ok" != "y" -a "$ok" != "Y" ]
do
	echo -e "Would you like to compile from scratch (y/n) \c"
	read ok
done

if [ "$ok" = "y" -o "$ok" = "Y" ]
then
	make mrproper
fi

cp $RASPI_MOUNT/.config .

make ARCH=arm CROSS_COMPILE=${CCPREFIX} oldconfig

echo "***************************************************************************************"
echo "Modify the kernel either by edting the .config file"
echo "(e.g. vim $KERNEL_SRC/.config) or using the menu using the following commands"
echo "	cd $KERNEL_SRC"
echo "	ARCH=arm CROSS_COMPILE=${CCPREFIX} make menuconfig"
echo "***************************************************************************************"
echo -e "When you are ready to continue \c"

ok=x

while [ "$ok" != 'c' ]
do
	echo -e "type c<ENTER> to continue or q<ENTER> to quit (c/q) \c"
	read ok
	
	if [ "$ok" = 'q' ]
	then
		exit
	fi
done

# Build the new kernel 
echo "Building the kernel..."
time (ARCH=arm CROSS_COMPILE=${CCPREFIX} make -j3)

# Compile the new kernel modules
echo "Colating the kernel modules and firmware..."
ARCH=arm CROSS_COMPILE=${CCPREFIX} INSTALL_MOD_PATH=${MODULES_TEMP} make modules_install

# Use the imagetool-uncompressed.py program to create an image
echo "Uncompressing the kernel image..."
cd ~/raspi/tools/mkimage
./imagetool-uncompressed.py ${KERNEL_SRC}/arch/arm/boot/zImage

#Copy the resulting kernel.img to the Raspberry Pi kernel directory
echo "Copying the kernel image..."
cp kernel.img ~/raspi/rpi
rm kernel.img

# Package up the modules into an archive 
echo "Packaging modules and firmware..."
cd $MODULES_TEMP/lib
tar -cvf $RASPI_MOUNT/modules.tar.gz modules 
tar -cvf $RASPI_MOUNT/firmware.tar.gz firmware 

echo "***************************************************************************************"
echo "If no errors were reported $RASPI_MOUNT_DIRECTORY will now contains the compiled kernel" 
echo "***************************************************************************************"

