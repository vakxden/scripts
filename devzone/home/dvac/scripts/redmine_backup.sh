#!/bin/bash
tar cfzh /home/dvac/redmine_backup.$(date +%d-%b-%Y_%H-%m-%S).tar.gz /home/dvac/redmine --exclude='*.log'
function remove_old_archives (){
        # $1 - directory for search of backup files (e.g "/home/dvac")
        # $2 - mask of searching backup files (e.g "redmine_backup.*.tar.gz")
        # Determine of numbers of files $2 in the $1 directory
        NUM=$(ls -f $1/$2 | wc -l)
        echo NUM=$NUM
        # If number of files is more than 2, then we will remove all files except the 2 most recent files
        if (( $NUM > 2 )); then
                HEAD_NUM=$(($NUM-2))
                echo HEAD_NUM=$HEAD_NUM
                for k in $(ls -lahtrf $1/$2 | head -$HEAD_NUM)
                do
                        rm -f $k
                done
        fi
}
remove_old_archives /home/dvac redmine_backup.*.tar.gz
