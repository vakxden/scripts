#!/bin/bash

# $1 = array with id's
# $2 = $dest

# check
if [ -z "$1" ]; then
    echo "array wit id's must be passed!"
    exit 1
fi
if [ -z "$2" ]; then
    echo "dest must be passed"
    exit 1
fi

# creating array
deploymentPackageId=($(echo "$1"))
# processed file
PFILE="/home/jenkins/irls-reader-artifacts/environment.json"

# for right block
if [ "$2" = "current" ]; then
        CURRENT="current"
elif [ "$2" = "stage" ]; then
        CURRENT="stage"
elif [ "$2" = "public" ]; then
        CURRENT="public"
elif [ "$2" = "NIGHT" ]; then
        CURRENT="night"
else
        echo [ERROR_DEST] ENVIRONMENT must be current or stage or public or NIGHT! Not $dest!
        exit 1
fi

# body
printf "start processing file $PFILE \n"
for ID in ${deploymentPackageId[@]}
do
        # count of strings in block, named $CURRENT
        a=$((($(cat $PFILE | wc -l)-8)/4))
        # find $ID in block named $CURRENT
        grep $CURRENT -A $a $PFILE | grep "\"$ID\"" #/dev/null 2>&1
        # if $ID not found check exist target name in current $ID in block named $CURRENT
        if [ $(echo $?) -eq 1 ]; then
                printf "\n"
                printf "environment named $CURRENT in file $PFILE not contains ID=$ID \n"
                TARGET_NAME=$(echo $ID | cut -d"_" -f 2-)
                printf "check contain name $TARGET_NAME in current ID=$ID, in environment named $CURRENT ... \n"
                grep $CURRENT -A $a $PFILE | grep -e '"[0-9a-z]\{7\}_'$TARGET_NAME'\",$' -e '"[0-9a-z]\{7\}_'$TARGET_NAME'\"$'
                if [ $(echo $?) -eq 1 ]; then
                        printf "environment $CURRENT in file $PFILE not contains target name = $TARGET_NAME \n"
                        printf "add $TARGET_NAME to $PFILE \n"
                        sed -i "/$CURRENT/a \\\t\\t\"$ID\"\," $PFILE
                else
                        printf "environment $CURRENT in file $PFILE contains target name = $TARGET_NAME \n"
                        printf "replacing old ID to new ID named $ID ... \n"
                        # number of line contain target name
                        num=$(grep $CURRENT -n -A $a $PFILE | grep -e '"[0-9a-z]\{7\}_'$TARGET_NAME'\",$' -e '"[0-9a-z]\{7\}_'$TARGET_NAME'\"$' | cut -d- -f1)
                        # replace line with old $ID in file $PFILE
                        sed -i "$num s/\(.*\)$TARGET_NAME/\t\t\"$ID/" $PFILE
                        printf "Done... \n"
                fi
        else
                printf "environment named $CURRENT in file $PFILE contains same ID=$ID \n"
                printf "\n"
        fi
done
