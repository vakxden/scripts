#!/bin/bash

SCRIPT_NAME=`basename $0`

### stage environment (for develop-, master- or audio- branches)
TMP_FILE="/tmp/tmpfile-$SCRIPT_NAME-stage"
if [ ! -f $TMP_FILE ]; then touch $TMP_FILE; else cat /dev/null > $TMP_FILE; fi #create tmp-file, if not exist and clean tmp-file, if exist
ART_STAGE_DIR="/home/jenkins/irls-reader-artifacts-stage"
LIST=$(ps aux | grep node.*_stage | grep -v grep  |  awk '{print $12}' | sed -e 's@server\/index_@@g' -e 's@_\(develop\|master\|audio\)_stage.js@@g')

for i in $LIST
do
        VALUE=($(head -2 /etc/apache2/sites-enabled/irls-stage-reader-$i-{develop,master,audio} 2>/dev/null | awk '{print $3}' | awk -F '/' '{print $5}' | sort | uniq))
        COUNT="$(cat $TMP_FILE | wc -l)"
        if [ "$COUNT" = "0" ]; then
                for y in ${VALUE[@]}
                do
                        echo "find $ART_STAGE_DIR -maxdepth 1 -type d -not -name $y" >> $TMP_FILE
                done
        else
                for y in ${VALUE[@]}
                do
                        printf " -not -name $y" >> $TMP_FILE
                done
        fi
done

COUNT_LINES=$(cat $TMP_FILE | tr '\n' ' ' | xargs -0 bash -c | wc -l)
TAIL=$(($COUNT_LINES-1))
cat $TMP_FILE | tr '\n' ' ' | xargs -0 bash -c | tail -"$TAIL" | xargs rm -rf
rm -f $TMP_FILE

#### NIGHT environment (only for develop branch)
#TMP_FILE="/tmp/tmpfile-$SCRIPT_NAME-NIGHT"
#TMP_FILE="/tmp/tmpfile-$SCRIPT_NAME-STAGE"
#if [ ! -f $TMP_FILE ]; then touch $TMP_FILE; else cat /dev/null > $TMP_FILE; fi #create tmp-file, if not exist and clean tmp-file, if exist
#ART_STAGE_DIR="/home/jenkins/irls-reader-artifacts-nightly"
#LIST=$(ps aux | grep node.*NIGHT | grep -v grep  |  awk '{print $12}' | sed 's@server\/index_@@g' | sed 's@_develop_NIGHT.js@@g')
#
#for i in $LIST
#do
#        VALUE=$( head -2 /etc/apache2/sites-enabled/irls-night-reader-$i-develop | awk '{print $3}' | awk -F '/' '{print $5}' | sort | uniq)
#        COUNT="$(cat $TMP_FILE | wc -l)"
#        if [ "$COUNT" = "0" ]; then
#                echo "find $ART_STAGE_DIR -maxdepth 1 -type d -not -name $VALUE" >> $TMP_FILE
#        else
#                printf " -not -name $VALUE" >> $TMP_FILE
#        fi
#done
#
#COUNT_LINES=$(cat $TMP_FILE | tr '\n' ' ' | xargs -0 bash -c | wc -l)
#TAIL=$(($COUNT_LINES-1))
#cat $TMP_FILE | tr '\n' ' ' | xargs -0 bash -c | tail -"$TAIL" | xargs rm -rf
#rm -f $TMP_FILE
