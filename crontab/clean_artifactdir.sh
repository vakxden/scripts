#!/bin/bash

while (($(df -h /fs/backup/ | tail -1 | awk '{print $2}' | sed 's/G//g')>150))
do
         echo "used more then 150 Gb"
        for i in $(ls -lahtr /home/jenkins/irls-reader-artifacts/ | head -6 | awk '{print $9}')
        do
                rm -rf /home/jenkins/irls-reader-artifacts/$i
        done
done
