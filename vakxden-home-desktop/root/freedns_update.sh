#!/bin/sh
#FreeDNS updater script

UPDATEURL="http://freedns.afraid.org/dynamic/update.php?VEBkTzhxMzFVMVVBQURPcFZWOEFBQUFROjc4NTE1NzA="
DOMAIN="vakxden.crabdance.com"

registered=$(nslookup $DOMAIN|tail -n2|grep A|sed s/[^0-9.]//g)
current=$(wget -q -O - http://checkip.dyndns.org|sed s/[^0-9.]//g)

[ "$current" != "$registered" ] && {
    wget -q -O /dev/null $UPDATEURL
        echo "FreeDNS $DOMAIN updated to $current" >> /tmp/freedns_sync.log
}
