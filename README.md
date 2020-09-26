# dbanned

This is a simple quick&dirty script that will install and configure a dhcp, tftpd and the old fashioned ifupdown.
The main purpose is to easily setup a "server" that provides DBAN for PXE bootin clients. 

It will aks for an interface, which is required for address and interface information as well as the dhcp server configuration. 
It will use 10.0.0.1/24 as dhcp server address on the given interface.

Additionally you may have to set up an dns, all downloading actions will be executed before dns configuration changes. 

Wipe Mode is DOD Short, if you want to use the non-interactive auto-nuke mode. 

Its was only tested under Ubuntu 18.04.

For Changes within installed components consult the appropriate MAN pages or docs...
Or take a look onto the code...

Be aware, any connected and pxe bootet device will be completely and unrecoverably overwritten!!!

