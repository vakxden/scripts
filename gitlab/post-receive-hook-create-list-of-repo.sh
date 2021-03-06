#!/bin/bash

TMP_FILE=temptemptemp
cat - > $TMP_FILE

newrev=$(cat $TMP_FILE | awk '{print $2}')

git_commit_notifier_config=/usr/local/lib/ruby/gems/2.0.0/gems/git-commit-notifier-0.12.5/config/git-notifier-config.yml

FILE=/home/jenkins/irls-reader-artifacts/branches.json

if [[ "$newrev" == "0000000000000000000000000000000000000000" ]]
then
        list=($( git for-each-ref --format="%(refname)" refs/heads | sed 's/refs\/heads\///g'))
        cat /dev/null > $FILE
        echo '{' >> $FILE
        counter=0
        a=$(( ${#list[@]} -1 ))
        while (( $counter < $a ))
        do
                echo -e '\t"'${list[$counter]}'",' >> $FILE
                ((counter++))
        done
        if [ "$counter" -eq "$a" ]
        then
                echo -e '\t"'${list[@]:(-1)}'"' >> $FILE
                ((counter++))
        fi
        echo '}'  >> $FILE
fi

cat $TMP_FILE | git-commit-notifier $git_commit_notifier_config
cat /dev/null > $TMP_FILE
