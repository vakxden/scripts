#!/bin/bash

TMP_FILE="/home/dvac/tmpfile"
touch $TMP_FILE
#LIST=$(ps aux | grep node | grep -v grep | awk '{print $12}' | awk -F"[__]" '{print $2}')
LIST=$(ps aux | grep node | grep -v grep | awk '{print $12}' | sed 's@server\/index_@@g' | sed 's@_develop.js@@g')

for i in $LIST
do
        VALUE=$(cat /home/dvac/apache2/conf/extra/proxypass-$i-develop.conf | grep 8890 | awk '{print $3}' | awk -F '/' '{print $5}' | sort | uniq)
        COUNT="$(cat $TMP_FILE | wc -l)"
        if [ "$COUNT" = "0" ]; then
                echo "find /home/dvac/irls-reader-artifacts -maxdepth 1 -type d -not -name $VALUE" >> $TMP_FILE
        else
                printf " -not -name $VALUE" >> $TMP_FILE
        fi
done

COUNT_LINES=$(cat $TMP_FILE | tr '\n' ' ' | xargs -0 bash -c | wc -l)
TAIL=$(($COUNT_LINES-1))
cat $TMP_FILE | tr '\n' ' ' | xargs -0 bash -c | tail -"$TAIL" | xargs rm -rf
rm -f $TMP_FILE
