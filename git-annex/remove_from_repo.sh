#!/bin/bash

IFS=$'\r\n'
ARRAY_WITH_PATH=($(cat /home/dvac/lib-sources_-_list_of_audio_files_-_master.txt))
for i in ${ARRAY_WITH_PATH[@]}
do
        echo remove $i
        rm -f $i
        git rm $i
        #DIRNAME=$(echo $i | sed -e "s/\ /\\ /g" -e "s/'/\\\'/g" | xargs dirname)
        DIRNAME=$(dirname $i)
        #BASENAME=$(echo $i | sed -e "s/\ /\\ /g" -e "s/'/\\\'/g" | xargs basename)
        BASENAME=$(basename $i)
        echo dirname is $DIRNAME
        echo basename is $BASENAME
        echo copying of file /home/dvac/lib-sources_audio_files_master/$BASENAME to $DIRNAME
        cp /home/dvac/lib-sources_audio_files_master/$BASENAME $DIRNAME
        git annex add $DIRNAME/$BASENAME
done

#git commit -am 'add next audio files by annex-git'
#git annex mirror --to origin
#git push origin HEAD:master
