#!/bin/bash
LOCAL_LOGS_PATH="/var/log/apache2"
REMOTE_LOGS_PATH="/opt/dev01-logs/apache"
SSH_USER="dvac"
SSH_HOST="dev02.design.isd.dp.ua"
REMOTE_GZIP_DIR="$REMOTE_LOGS_PATH/gzip"
REMOTE_UNGZIP_DIR="$REMOTE_LOGS_PATH/ungzip"
REMOTE_CURRENT_DIR="$REMOTE_LOGS_PATH/current"
cd $LOCAL_LOGS_PATH
LIST=($(ls access.log access.log-[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9].gz))
for i in ${LIST[@]}
do
        #echo processing $i
        MD5SUM_LOCAL=$(md5sum $i | awk '{ print $1 }')
        #echo MD5SUM_LOCAL is $MD5SUM_LOCAL
        MD5SUM_REMOTE=$(ssh $SSH_USER@$SSH_HOST "if [ -f "$REMOTE_LOGS_PATH"/"$i" ]; then md5sum "$REMOTE_LOGS_PATH"/"$i" | awk '{print \$1}'; fi")
        #echo MD5SUM_REMOTE is $MD5SUM_REMOTE
        if [ -z $MD5SUM_REMOTE ] || ! [ $MD5SUM_LOCAL = $MD5SUM_REMOTE ]; then
                ### determine whether a particular file is compressed
                if [[ $(file $i | grep gzip) ]]; then
                        NAME_FOR_RENAME=$(echo $i | sed 's@\.gz@@g')
                        ssh $SSH_USER@$SSH_HOST "if [ ! -d $REMOTE_GZIP_DIR ]; then mkdir -p $REMOTE_GZIP_DIR; fi"
                        scp $LOCAL_LOGS_PATH/$i $SSH_USER@$SSH_HOST:$REMOTE_GZIP_DIR/
                        ssh $SSH_USER@$SSH_HOST "if [ ! -d $REMOTE_UNGZIP_DIR ]; then mkdir -p $REMOTE_UNGZIP_DIR; fi"
                        ssh $SSH_USER@$SSH_HOST "gunzip $REMOTE_GZIP_DIR/$i -c > $REMOTE_UNGZIP_DIR/$NAME_FOR_RENAME"
                elif [ "$i" = "access.log" ]; then
                        ssh $SSH_USER@$SSH_HOST "if [ ! -d $REMOTE_CURRENT_DIR ]; then mkdir -p $REMOTE_CURRENT_DIR; fi"
                        scp $LOCAL_LOGS_PATH/$i $SSH_USER@$SSH_HOST:$REMOTE_CURRENT_DIR/
                fi
        fi
done
