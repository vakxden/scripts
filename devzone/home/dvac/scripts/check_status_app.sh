#!/bin/bash

DATE=$(date +%b-%d-%Y_%H-%M-%S)
MAILLIST="irls@isd.dp.ua"

# for array of targes
TARGET=(ocean ffa irls-audio irls-audiobywords irls-ocean irls-epubtest)
for i in ${TARGET[@]}
do
        STATUS=$(curl -o /dev/null -s -I -w '%{http_code}\n' https://irls.isd.dp.ua/$i/develop/portal/)
        if [ $STATUS  -ne  200 ]; then
                PID=$( ps aux | grep -v "grep node" | grep "node server/index_$i.develop.js" | awk '{print $2}')
                if [ ! -z "$PID" ];then
                        kill -9 $PID
                fi
                sleep 5
                if ! ps aux | grep -v "grep node" | grep "node server/index_$i.develop.js"; then
                        echo -e "Status code for URL https://irls.isd.dp.ua/$i/develop/portal/ is $STATUS\nProcess of node (~/node/bin/node server/index_'$i'_develop.js) is not running" | mail -s "Target $i on the devzone is not available!" $MAILLIST
                        DIRNAME=$(cat ~/apache2/conf/extra/proxypass-$i-develop.conf | grep  8890 | awk '{print $3}' | awk -F '/' '{print $5}' | sort | uniq)
                        cd ~/irls-reader-artifacts/$DIRNAME/
                        if [ -f nohup.out ]; then mv nohup.out nohup.out.old.$DATE; fi
                        nohup ~/node/bin/node server/index_"$i"_develop.js >> nohup.out 2>&1 &
                        sleep 5
                        echo "It's OK! Check please next URL - https://irls.isd.dp.ua/$i/develop/portal/" | mail -s "Target $i on the devzone is available again!" $MAILLIST
                else
                        echo -e "Status code for URL https://irls.isd.dp.ua/$i/develop/portal/ is $STATUS\nApparently something happened with the web server, because process of node (~/node/bin/node server/index_'$i'_develop.js) is running." | mail -s "Target $i on the devzone is not available!" $MAILLIST
                fi
        fi
done
