#!/bin/bash

DATE=$(date +%b-%d-%Y_%H-%M-%S)
#MAILLIST="irls@isd.dp.ua,vakxden@gmail.com"
MAILLIST="dvac@isd.dp.ua,vakxden@gmail.com"

for BRANCH in develop master audio
do
        if [ "$BRANCH" = "develop" ]; then
               TARGET=(ocean ffa irls-ocean irls-epubtest)
        elif [ "$BRANCH" = "master" ]; then
               TARGET=(ocean-master ffa-master)
        elif [ "$BRANCH" = "audio" ]; then
               TARGET=(irls-audio irls-audiobywords)
        fi

        for i in ${TARGET[@]}
        do
                if [ "$BRANCH" = "develop" ] || [ "$BRANCH" = "master" ]; then
                        APP_URL="https://irls.isd.dp.ua/$i/$BRANCH/portal/"
                elif [ "$BRANCH" = "audio" ]; then
                        APP_URL="https://irls.isd.dp.ua/$i/$BRANCH/portal/artifacts/index.html"
                fi

                INDEX_FILE=server/index_"$i"_"$BRANCH"_public.js
                STATUS=$(curl --user irls-team:ATh8ayoh -o /dev/null -s -I -w '%{http_code}\n' $APP_URL)
                if [ $STATUS  -ne  200 ]; then
                        PID=$( ps aux | grep -v "grep node" | grep "node.*$INDEX_FILE" | awk '{print $2}')
                        if [ ! -z "$PID" ];then
                                sleep 3
                                PID2=$( ps aux | grep -v "grep node" | grep "node.*$INDEX_FILE" | awk '{print $2}')
                                if [ ! -z "$PID2" ];then
                                        kill -9 $PID2
                                fi
                        fi
                        sleep 2
                        if ! ps aux | grep -v "grep node" | grep "node.*$INDEX_FILE"; then
                                DIRNAME=$(cat ~/apache2/conf/extra/proxypass-$i-$BRANCH.conf | grep  8890 | awk '{print $3}' | awk -F '/' '{print $5}' | sort | uniq)
                                cd ~/irls-reader-artifacts/$DIRNAME/
                                if [ ! -f ~/irls-reader-artifacts/$DIRNAME/status_deploy.txt ]; then
                                        echo -e "Status code for URL $APP_URL is $STATUS\nProcess of node (~/node/bin/node $INDEX_FILE) is not running" | mail -s "Target $i on the devzone is not available!" $MAILLIST
                                else
                                        continue
                                fi
                                if [ -f nohup.out ]; then mv nohup.out nohup.out.old.$DATE; fi
                                nohup ~/node/bin/node $INDEX_FILE >> nohup.out 2>&1 &
                                sleep 3
                                echo "It's OK! Check please next URL - $APP_URL" | mail -s "Target $i on the devzone is available again!" $MAILLIST
                        else
                                echo -e "Status code for URL $APP_URL is $STATUS\nApparently something happened with the web server, because process of node (~/node/bin/node $INDEX_FILE) is running." | mail -s "Target $i on the devzone is not available!" $MAILLIST
                        fi
                fi
        done
done
