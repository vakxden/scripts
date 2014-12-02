#!/bin/bash

DATE=$(date +%b-%d-%Y_%H-%M-%S)
#MAILLIST="irls@isd.dp.ua,vakxden@gmail.com"
MAILLIST="dvac@isd.dp.ua,vakxden@gmail.com"

for BRANCH in develop master audio
do
        if [ "$BRANCH" = "develop" ]; then
               TARGET=(ocean ffa irls-ocean irls-epubtest)
        elif [ "$BRANCH" = "master" ]; then
               TARGET=(ocean ffa)
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

                STATUS=$(curl --user irls-team:ATh8ayoh -o /dev/null -s -I -w '%{http_code}\n' $APP_URL)
                if [ $STATUS  -ne  200 ]; then
                        PID=$( ps aux | grep -v "grep node" | grep "node server/index_$i.$BRANCH.js" | awk '{print $2}')
                        if [ ! -z "$PID" ];then
                                kill -9 $PID
                        fi
                        sleep 5
                        if ! ps aux | grep -v "grep node" | grep "node server/index_$i.$BRANCH.js"; then
                                DIRNAME=$(cat ~/apache2/conf/extra/proxypass-$i-$BRANCH.conf | grep  8890 | awk '{print $3}' | awk -F '/' '{print $5}' | sort | uniq)
                                cd ~/irls-reader-artifacts/$DIRNAME/
                                if [ ! -e ~/irls-reader-artifacts/$DIRNAME/status_deploy.txt ]; then
                                        echo -e "Status code for URL $APP_URL is $STATUS\nProcess of node (~/node/bin/node server/index_$i\_$BRANCH.js) is not running" | mail -s "Target $i on the devzone is not available!" $MAILLIST
                                else
                                        continue
                                fi
                                if [ -f nohup.out ]; then mv nohup.out nohup.out.old.$DATE; fi
                                nohup ~/node/bin/node server/index_"$i"_$BRANCH.js >> nohup.out 2>&1 &
                                sleep 5
                                echo "It's OK! Check please next URL - $APP_URL" | mail -s "Target $i on the devzone is available again!" $MAILLIST
                        else
                                echo -e "Status code for URL $APP_URL is $STATUS\nApparently something happened with the web server, because process of node (~/node/bin/node server/index_$i\_$BRANCH.js) is running." | mail -s "Target $i on the devzone is not available!" $MAILLIST
                        fi
                fi
        done
done
