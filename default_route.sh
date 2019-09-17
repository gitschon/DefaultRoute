#!/bin/bash

prov1_gw="" #pri prov's gw ip address
prov2_gw="" #backup prov's gw ip address

prov1_ip="" #pri prov's ip address

# Dns servers ip addresses
google_dns="8.8.4.4"
yandex_dns="77.88.8.8"
cloudflare_dns="1.1.1.1"

log="/root/default_route.log" #path to the log file
####################################################################################

case "$1" in
  start)
    echo "Starting $0"

    # IF dg not exists
    if  [[ -z `ip route | grep default` ]] ; then
        ip route add default via $prov1_gw
        echo "def gw is added - $prov1_gw" >> $log
    fi
    ####################################################################################
    
    status_pri=`ping  -c 10 $google_dns | grep "packets transmitted" | cut -d "," -f 2 | cut -d " " -f 2`
    status_sec=`ping  -c 10 $yandex_dns | grep "packets transmitted" | cut -d "," -f 2  | cut -d " " -f 2`
    cloudflare=`ping  -c 10 $cloudflare_dns | grep "packets transmitted" | cut -d "," -f 2  | cut -d " " -f 2` 
    prov1gw=`ping  -c 10 $prov1_gw | grep "packets transmitted" | cut -d "," -f 2  | cut -d " " -f 2` 
    
    def_gw=`ip route | grep default | cut -d " " -f 3`
    
    ####################################################################################
    
    if  [[ $status_pri -ge "8" || $cloudflare -ge "8" ]]; then
        if  [[ $def_gw != $prov1_gw ]] ; then
            echo "---------------------------------------" >> $log
            echo "`date` - $def_gw --> $prov1_gw" >> $log
            ip route del default
            ip route add default via $prov1_gw
            /usr/sbin/conntrack -F >> $log 2>&1
    	    echo "`date` - pri gw added $prov1_gw" >> $log
            echo "---------------------------------------" >> $log
        fi
    else
        echo "---------------------------------------" >> $log
        echo "`date` Test ping $google_dns - Packets returns from 10 is  $status_pri" >> $log
        echo "`date` Test ping $cloudflare_dns - Packets returns from 10 is  $cloudflare" >> $log
        echo "`date` Test ping $prov1_gw - Packets returns from 10 is  $prov1gw" >> $log
        echo "`date` - $def_gw --> $prov2_gw" >> $log
        if  [[ $status_sec -ge "8" ]] ; then
            echo "`date` - Sec channel ping is Ok $status_sec" >> $log
            if  [[ $def_gw != $prov2_gw ]] ; then
                echo "`date` - $def_gw --> $prov2_gw" >> $log
                ip route del default
                ip route add default via $prov2_gw
                /usr/sbin/conntrack -F >> $log 2>&1
                echo "`date` - pri gw added $prov2_gw" >> $log
            fi
        fi
    fi

   ####################################################################################
  ;;
  install)
    echo "Installing the routes" >> $log

    # This code checks if T1 exists in the system, if not, it will add it
    my_table=`cat /etc/iproute2/rt_tables | grep T1 | cut -f 2`

    if [[  -z $my_table ]]; then
        echo "101     T1" >> /etc/iproute2/rt_tables
        echo "Routing table T1 added in the system" >> $log
    else
        echo "Routing table T1 founded in the system" >> $log
    fi

    # Test for pri channel to verizon public dns
    ip route add "$google_dns/32" via $prov1_gw
    ip route add "$cloudflare_dns/32" via $prov1_gw

    # Test for backup channel to yandex public dns
    ip route add "$yandex_dns/32" via $prov2_gw

    # Create default route to the pri prov via prov1_gw
    ip route add default via $prov1_gw table T1

    # It needs for the server ability to ansver from pri prov\
    # ip to external internet hosts while the default gateway is $prov2_gw. 
    ip rule add from $prov1_ip table T1

  ;;
  *)
	  echo "Usage: $0 {start|install(You need to install this script first)}"
	  echo "Autostart: For example you can add \"$0 install\" into rc.local"
    exit 1
    ;;
esac

exit 0 
