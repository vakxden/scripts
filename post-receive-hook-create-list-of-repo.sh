#!/bin/bash

oldrev=$1
newrev=$2
branch=$3

FILE=/home/jenkins/irls-reader-artifacts/branches.json

while read oldrev newrev branch ; do
        if [[ "$newrev" == "0000000000000000000000000000000000000000" ]]; then
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
                                        counter=$(( $counter + 1 ))
                                fi
                echo '}'  >> $FILE
        fi
done
