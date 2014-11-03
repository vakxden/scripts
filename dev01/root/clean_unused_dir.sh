#!/bin/bash

SCRIPT_NAME=`basename $0`

#### STAGE (only for develop)
TMP_FILE="/tmp/tmpfile-$SCRIPT_NAME-STAGE"
cat /dev/null > $TMP_FILE #clean file, if exist
ART_STAGE_DIR="/home/jenkins/irls-reader-artifacts-stage"
if [ ! -f $TMP_FILE ]; then touch $TMP_FILE; fi #create file, if not exist
LIST=$(ps aux | grep node.*STAGE | grep -v grep  |  awk '{print $12}' | sed 's@server\/index_@@g' | sed 's@_develop_STAGE.js@@g')

for i in $LIST
do
        VALUE=$( head -2 /etc/apache2/sites-enabled/irls-stage-reader-$i-develop | awk '{print $3}' | awk -F '/' '{print $5}' | sort | uniq)
        COUNT="$(cat $TMP_FILE | wc -l)"
        if [ "$COUNT" = "0" ]; then
                echo "find $ART_STAGE_DIR -maxdepth 1 -type d -not -name $VALUE" >> $TMP_FILE
        else
                printf " -not -name $VALUE" >> $TMP_FILE
        fi
done

COUNT_LINES=$(cat $TMP_FILE | tr '\n' ' ' | xargs -0 bash -c | wc -l)
TAIL=$(($COUNT_LINES-1))
cat $TMP_FILE | tr '\n' ' ' | xargs -0 bash -c | tail -"$TAIL" | xargs rm -rf
rm -f $TMP_FILE

### NIGHT (only for develop)
TMP_FILE="/tmp/tmpfile-$SCRIPT_NAME-NIGHT"
cat /dev/null > $TMP_FILE #clean file, if exist
ART_STAGE_DIR="/home/jenkins/irls-reader-artifacts-nightly"
if [ ! -f $TMP_FILE ]; then touch $TMP_FILE; fi #create file, if not exist
LIST=$(ps aux | grep node.*NIGHT | grep -v grep  |  awk '{print $12}' | sed 's@server\/index_@@g' | sed 's@_develop_NIGHT.js@@g')

for i in $LIST
do
        VALUE=$( head -2 /etc/apache2/sites-enabled/irls-night-reader-$i-develop | awk '{print $3}' | awk -F '/' '{print $5}' | sort | uniq)
        COUNT="$(cat $TMP_FILE | wc -l)"
        if [ "$COUNT" = "0" ]; then
                echo "find $ART_STAGE_DIR -maxdepth 1 -type d -not -name $VALUE" >> $TMP_FILE
        else
                printf " -not -name $VALUE" >> $TMP_FILE
        fi
done

COUNT_LINES=$(cat $TMP_FILE | tr '\n' ' ' | xargs -0 bash -c | wc -l)
TAIL=$(($COUNT_LINES-1))
cat $TMP_FILE | tr '\n' ' ' | xargs -0 bash -c | tail -"$TAIL" | xargs rm -rf
rm -f $TMP_FILE
