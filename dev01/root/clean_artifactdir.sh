#!/bin/bash

# Current artifacts directory
while (($(df -h /fs/backup/ | tail -1 | awk '{print $2}' | sed 's/G//g')>250))
do
        printf " /fs/backup/ used more then 250 Gb\n"
        for i in $(ls -lahtr /home/jenkins/irls-reader-artifacts/ | egrep -v "branches.json|trendcountbooks.png|environment.json" | head -6 | awk '{print $9}')
        do
                rm -rf /home/jenkins/irls-reader-artifacts/$i
        done
done

## Stage artifacts directory
#while (($(df -h /home | tail -1 | awk '{print $2}' | sed 's/G//g')>150))
#do
#       echo "/home used more then 150 Gb\n"
#        for i in $(ls -lahtr /home/jenkins/irls-reader-artifacts-stage/ | head -6 | awk '{print $9}')
#        do
#                rm -rf /home/jenkins/irls-reader-artifacts-stage/$i
#        done
#done
