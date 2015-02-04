#!/bin/bash
LOCAL_LOGS_PATH="/var/log/apache2"
REMOTE_LOGS_PATH="/opt/dev01-logs/apache"
SSH_USER="dvac"
SSH_HOST="dev02.design.isd.dp.ua"
cd $LOCAL_LOGS_PATH
LIST=($(ls access.log access.log-[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9].gz))
for i in ${LIST[@]}
do
        #echo processing $i
        MD5SUM_LOCAL=$(md5sum $i | awk '{ print $1 }')
        #echo MD5SUM_LOCAL is $MD5SUM_LOCAL
        MD5SUM_REMOTE=$(ssh $SSH_USER@$SSH_HOST "if [ -f "$REMOTE_LOGS_PATH"/"$i" ]; then md5sum "$REMOTE_LOGS_PATH"/"$i" | awk '{print \$1}'; fi")
        #echo MD5SUM_REMOTE is $MD5SUM_REMOTE
        if [ -z $MD5SUM_REMOTE ] || ! [ $MD5SUM_LOCAL = $MD5SUM_REMOTE ]; then scp $LOCAL_LOGS_PATH/$i $SSH_USER@$SSH_HOST:$REMOTE_LOGS_PATH/; fi
done
