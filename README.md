# DefaultRoute
This script will allow you switch automatically to the backup internet provider if the main provider is down.

To use this script you need to have two internet providers(primary and backup). Please fill in the script primary and backup provider's default gateway's ip addreses . After that you must fill your ip address of the primary internet provider. Plese make default_route.sh executable file using comand "chmod +x default_route.sh".

For autostart this script with linux system you can insert "default_route.sh install" command to rc.local file before exit 0.

Plese make sure that you have /usr/sbin/conntrack program in you linux system. To install this program execute "apt install conntrack".

This script was tested and used only in ubuntu 14/16 LTS. 
And remember, absolutely no warranty!!! You can use this script on you own risk.
