#!/bin/bash

#ppp0      Link encap:Point-to-Point Protocol  
#          inet addr:46.98.20.112  P-t-P:212.115.225.242  Mask:255.255.255.255

# searching neighbor with open 23 port for gateway 212.115.225.242
GATE="212.115.225.242"
for i in {50..100}
do
	A=()
	#echo "Start scanning network 46.98.$i.0/24..."
	A=($(nmap 46.98.$i.0/24 -p 23 | grep open -B3 | grep "Nmap scan report for" | awk -F "(" '{print $2}' | sed 's/)//g'))
	#echo "IP-addresses with open 23 port for network 46.98.$i.0/24:"
	#echo ${A[@]}
	for y in "${A[@]}"
	do
		traceroute $y | grep $GATE
		if [ $(echo $?) -eq 0 ]; then
			echo "Neighbor is $y"
		fi
	done
done

#Neighbor is 46.98.2.142
#Neighbor is 46.98.15.178
#Neighbor is 46.98.23.221
#Neighbor is 46.98.27.19
#Neighbor is 46.98.34.119
#Neighbor is 46.98.39.226
#Neighbor is 46.98.43.176
#Neighbor is 46.98.50.94


#Not is neighbor: telnet 46.98.13.94 23 (admin/admin) ASUS RT-G32
