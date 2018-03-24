#! /bin/bash

get_ipv4(){
    ipreg='\([0-9]\{1,3\}\.\)\{3\}[0-9]\{1,3\}'
    ip=$(ip addr show $1 | grep $ipreg | awk '{print $2}')
    echo $ip
}

scan(){
    echo -ne "\n"
    echo -e "Network Device \033[31m$1\033[m"

    if [ -z "$2" ]; then
        echo -e "\033[31mThis device may not be connected to LAN\033[m"
        return
    fi

    echo -e "\033[36mIP\t\tMAC\t\t\tOUI\033[m"

    ipreg='\([0-9]\{1,3\}\.\)\{3\}[0-9]\{1,3\}'
    lan_ips=$(nmap -sP $2 | grep $ipreg | sed 's/[^0-9\.]//g')

    for lan_ip in $lan_ips
    do
        if [ "$lan_ip" = "$(echo $2 | sed 's/\/[0-9]\{1,2\}//g')" ]; then
            continue
        fi

        mac=$(grep "$lan_ip[[:space:]]" /proc/net/arp | awk '{print $4}')
        mac=$(echo $mac | tr 'a-z' 'A-Z')
        oui=$(echo $mac | cut -c 1-8 | tr ':' '-')
        manu=$(grep $oui ./oui.txt | awk '{print $3}' FS='\t')
        echo -e "$lan_ip\t$mac\t$manu"
    done
}

update(){
    echo "Update oui.txt, please wait..."
    curl http://standards-oui.ieee.org/oui.txt > ./oui.txt
    echo "Update complete"
}

show_devices(){
    for device in $1; do
        echo -e "\033[33m$device\033[m"
    done
}

# main
if [ "$1" = "update" ]; then
    update
else
    devices=$(ip addr show | grep '^[0-9]*:' | grep ':.*:' -o | grep '[a-z0-9]*' -o)
    devices=($devices)      # string to array
    unset devices[0]
    device_num=${#devices[@]}

    if [ $device_num -eq 1 ]; then
        scan ${devices[1]} $(get_ipv4 ${devices[1]})
        echo -ne "\n"
    elif [ $device_num -eq 0 ]; then
        echo -e "\033[31mYou may not have network device\033[m"
    else
        echo "You have more than one network device:"
        show_devices "${devices[*]}"
        echo -n "Please select (default=all): "
        read device
        if [ -z $device ]; then
            for device in ${devices[*]}; do
                scan $device $(get_ipv4 $device)
            done
        else
            scan $device $(get_ipv4 $device)
        fi
            echo -ne "\n"
    fi
fi
