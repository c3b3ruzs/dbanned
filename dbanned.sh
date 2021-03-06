#!/bin/bash

if ! [ $(id -u) = 0 ]; then
	echo "Run Script as root!"
	exit 1
else
	# update, dhcp und tft server ifupdown installation 
	apt-get update 
	apt-get install ifupdown -y
	apt-get install dnsmasq -y
	apt-get install tftpd-hpa -y 
	apt-get install openssh-server -y
	
	inf="/etc/network/interfaces"
	res="/etc/resolv.conf"
	
	read -p "which interface? (enp0s3, eht0, etc...): " iface
	read -p "which dns? (xxx.xxx.xxx.xxx): " dns
	nms="nameserver "
	newnameserver=$nms$dns
	
	# configure dhcp server
	echo " 
# Add these to the top of the file
dhcp-range=10.0.0.2,10.0.0.254,6h
dhcp-boot=pxelinux.0,dban-server,10.0.0.1
interface="$iface"
" > /etc/dnsmasq.conf
			
	# enable tftpd at boot
	sed -i '3s/.*/start on (local-filesystems and net-device-up IFACE=enp0s3)/' /etc/init/tftpd-hpa.conf
	
	# interfaces configuration
	echo "	
# The loopback network interface
auto lo
iface lo inet loopback
			
#"$iface" 
allow-hotplug "$iface"
auto "$iface"
iface "$iface" inet static
address 10.0.0.1
netmask 255.255.255.0
" > $inf
		
	# Download DBAN iso file
	mkdir /dbanned
	wget -O /dbanned/dban.iso https://sourceforge.net/projects/dban/files/dban/dban-2.3.0/dban-2.3.0_i586.iso/download
	mount -o loop /dbanned/dban.iso /mnt
	cp /mnt/* /var/lib/tftpboot
	cd /var/lib/tftpboot
	
	# Download the pxelinux.0 file and a default configuration file with a single, default option to boot DBAN and start 'autonuke', which will automatically wipe all attached drives.
	wget http://mirrors.tummy.com/pub/ftp.ubuntulinux.org/ubuntu/dists/precise/main/installer-i386/current/images/netboot/ubuntu-installer/i386/pxelinux.0
	mkdir /var/lib/tftpboot/pxelinux.cfg
	echo " 
DEFAULT autonuke

LABEL autonuke
KERNEL dban.bzi
APPEND nuke="dwipe --autonuke --method dod522022m" silent
	" > /var/lib/tftpboot/pxelinux.cfg/default
	
	# Lastly, make sure our clients can read the files.
	sudo chmod -R 755 /var/lib/tftpboot/
	
	# change dns 
	sed -i "17s/.*/$newnameserver/" $res
	
	# activate interface and enable service start at boot	
	ifdown --force $iface lo && ifup -a
	systemctl unmask networking
 	systemctl enable networking
 	systemctl restart networking
	
	# start tftpd
	systemctl restart tftpd-hpa
	
	# Stop, Mask und purge unwanted deamons 
	systemctl stop systemd-networkd.socket systemd-networkd networkd-dispatcher systemd-networkd-wait-online
	systemctl disable systemd-networkd.socket systemd-networkd networkd-dispatcher systemd-networkd-wait-online
	systemctl mask systemd-networkd.socket systemd-networkd networkd-dispatcher systemd-networkd-wait-online
	apt-get --assume-yes purge nplan netplan.io
	
	# Restart the affected services
	sudo /etc/init.d/networking restart
	sudo /etc/init.d/dnsmasq restart
	echo "services should run, if something fails it might be the dns, so check resolv.conf again"
	systemctl status networking.service
	systemctl status dnsmasq.service
	systemctl status tftpd-hpa.service
fi
