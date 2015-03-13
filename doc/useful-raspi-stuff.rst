Useful Raspberry Pi stuff
=========================

To create an SD card on a linux box
-----------------------------------
    sudo dd bs=1M if=2015-01-31-raspbian.img of=/dev/sdb
    
Make sure your pi is up to date
-------------------------------
::
	sudo apt-get update
	sudo apt-get upgrade

Create a user
-------------
::
	sudo adduser <username>
	
Add to sudoers file
-------------------
::
	sudo vim /etc/sudoers

Add your public key to the pi
-----------------------------

From the computer you want to access the pi from
::
	config-ssh-key <name of pi in /etc/hosts> <public key file>
	

