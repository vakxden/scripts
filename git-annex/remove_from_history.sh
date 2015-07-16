#!/bin/bash

IFS=$'\r\n'
ARRAY_WITH_PATH=($(cat /home/git/lib-sources_-_list_of_audio_files_-_master.txt))
for i in ${ARRAY_WITH_PATH[@]}
do
        git filter-branch --force --index-filter 'git rm --cached --ignore-unmatch "'$i'"' --prune-empty --tag-name-filter cat -- --all
done
