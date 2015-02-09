#!/bin/bash

ART_DIR="/home/jenkins/irls-reader-artifacts/"
APACHE_CONFIGS_DIR="/etc/apache2/sites-enabled/"
LIST_OF_DIR=($(find $ART_DIR -maxdepth 1 -type d))
LENGTH_OF_LIST_OF_DIR=${#LIST_OF_DIR[@]}
for (( i=1; i<${LENGTH_OF_LIST_OF_DIR}; i++ ));
do
        y=$(echo ${LIST_OF_DIR[$i]} | sed "s@$ART_DIR@@g")
        if ! grep -qr $y $APACHE_CONFIGS_DIR; then rm -rf ${LIST_OF_DIR[$i]}; fi
done
service apache2 stop && service apache2 start
