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
#Neighbor is 46.98.26.1
#Neighbor is 46.98.31.41
#Neighbor is 46.98.34.201
#Neighbor is 46.98.35.60
#Neighbor is 46.98.35.252
#Neighbor is 46.98.37.32
#Neighbor is 46.98.37.84
#Neighbor is 46.98.39.163
#Neighbor is 46.98.39.208
#Neighbor is 46.98.43.87
#Neighbor is 46.98.43.128
#Neighbor is 46.98.43.253
#Neighbor is 46.98.46.170
#Neighbor is 46.98.47.72
#Neighbor is 46.98.50.147
#Neighbor is 46.98.53.159
#Neighbor is 46.98.54.254
#Neighbor is 46.98.56.213
#Neighbor is 46.98.58.136
#Neighbor is 46.98.62.185
#Neighbor is 46.98.63.2
#Neighbor is 46.98.63.56
#Neighbor is 46.98.67.144
#Neighbor is 46.98.69.189
#Neighbor is 46.98.72.133
#Neighbor is 46.98.74.69
#Neighbor is 46.98.74.152
#Neighbor is 46.98.76.137
#Neighbor is 46.98.77.44
#Neighbor is 46.98.80.64
#Neighbor is 46.98.86.10
#Neighbor is 46.98.86.212
#Neighbor is 46.98.87.254
#Neighbor is 46.98.89.223
#Neighbor is 46.98.99.92
#Neighbor is 46.98.101.230
#Neighbor is 46.98.104.221
#Neighbor is 46.98.108.241
#Neighbor is 46.98.110.72
#Neighbor is 46.98.115.185
#Neighbor is 46.98.117.176
#Neighbor is 46.98.118.45
#Neighbor is 46.98.118.133
#Neighbor is 46.98.120.150
#Neighbor is 46.98.123.138
#Neighbor is 46.98.123.208
#Neighbor is 46.98.124.32
#Neighbor is 46.98.184.70
#Neighbor is 46.98.185.81
#Neighbor is 46.98.185.144
#Neighbor is 46.98.187.131
