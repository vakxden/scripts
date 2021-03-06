#!/bin/bash
TMP_FILE=temptemptemp
cat /dev/null > $TMP_FILE
cat - > $TMP_FILE

NEWREW=$(cat $TMP_FILE | awk '{print $2}')
BRANCH=$(cat $TMP_FILE | awk '{print $3}' | sed 's/refs\/heads\///g')
JSON="/home/jenkins/irls-reader-artifacts/irls-reader-build.json"
if ! [ "$BRANCH" == "develop" ]; then
        NUM=$(grep lastReaderBranchCommit $JSON -n | awk -F ":" '{print $1}')
        sed -i "$NUM""s#\"lastReaderBranchCommit.*#\"lastReaderBranchCommit\": \""$BRANCH"\",#g" $JSON
fi

git_commit_notifier_config="/usr/local/lib/ruby/gems/2.1.0/gems/git-commit-notifier-0.12.6/config/git-notifier-config"

FILE=/home/jenkins/irls-reader-artifacts/branches.json

if [[ "$NEWREW" == "0000000000000000000000000000000000000000" ]]
then
        list=($( git for-each-ref --format="%(refname)" refs/heads | sed 's/refs\/heads\///g'))
        cat /dev/null > $FILE
        echo '{' >> $FILE
        echo -e '\t"branches":' >> $FILE
        echo -e '\t\t[' >> $FILE
        counter=0
        a=$(( ${#list[@]} -1 ))
        while (( $counter < $a ))
        do
                echo -e '\t\t\t"'${list[$counter]}'",' >> $FILE
                ((counter++))
        done
        if [ "$counter" -eq "$a" ]
        then
                echo -e '\t\t\t"'${list[@]:(-1)}'"' >> $FILE
                ((counter++))
        fi
        echo -e '\t\t]' >> $FILE
        echo '}'  >> $FILE
fi

if [ `git rev-parse --abbrev-ref develop` = "develop" ]; then
#       git fetch origin
#       git checkout develop
#       git merge origin/develop
        git push github develop
fi

cat $TMP_FILE | git-commit-notifier $git_commit_notifier_config
