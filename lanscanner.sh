#! /bin/sh

ipreg='\([0-9]\{1,3\}\.\)\{3\}[0-9]\{1,3\}'

ips=$(ip addr show | grep $ipreg | awk '{print $2}')

for ip in $ips
do
    if [ "$ip" = "127.0.0.1/8" ]; then
        continue
    fi

    lan_ips=$(nmap -sP $ip | grep $ipreg | sed 's/[^0-9\.]//g')
    
    for lan_ip in $lan_ips
    do
        if [ "$lan_ip" = "$(echo $ip | sed 's/\/[0-9]\{1,2\}//g')" ]; then
            continue
        fi

        mac=$(grep "$lan_ip[[:space:]]" /proc/net/arp | awk '{print $4}')
        mac=$(echo $mac | tr 'a-z' 'A-Z')
        oui=$(echo $mac | cut -c 1-8 | tr ':' '-')
        manu=$(grep $oui ./oui.txt | awk '{print $3}' FS='\t')
        echo "$lan_ip\t$mac\t$manu"
    done
done
