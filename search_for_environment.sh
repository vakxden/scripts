#!/bin/bash

# example list of id's: 
# 11111111111111111111_puddle 111111111111111111111_e87c5e722febc61e5c5be_lake 111111111111111111111_ocean
# if list of id's contained in array A=(11111111111111111111_puddle 111111111111111111111_e87c5e722febc61e5c5be_lake 111111111111111111111_ocean)
# right running script is: ./search_for_environment.sh "$(echo ${A[@]})" "DEVELOPMENT"
# else: ./search_for_environment.sh "11111111111111111111_puddle 111111111111111111111_e87c5e722febc61e5c5be_lake 111111111111111111111_ocean" "DEVELOPMENT"

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
if [ "$2" = "DEVELOPMENT" ]; then
        CURRENT="current"
elif [ "$2" = "STAGE" ]; then
        CURRENT="stage"
elif [ "$2" = "LIVE" ]; then
        CURRENT="live"
else
	echo [ERROR_DEST] dest must be DEVELOPMENT or STAGE or LIVE! Not $dest!
	exit 1
fi

# body
printf "start processing file $PFILE \n"
for ID in ${deploymentPackageId[@]}
do
	# count of strings in block, named $CURRENT
	a=$((($(cat $PFILE | wc -l)-8)/3))
	# find $ID in block named $CURRENT
	grep $CURRENT -A $a $PFILE | grep $ID #/dev/null 2>&1
	# if $ID not found check exist name $FACET in current $ID in block named $CURRENT
	if [ $(echo $?) -eq 1 ]; then
		printf "\n"
		printf "environment named $CURRENT in file $PFILE not contains ID=$ID \n"
		FACET=$(echo $ID | sed 's/^.*_//g')
		printf "check whether a facet named $FACET in current ID=$ID, in environment named $CURRENT ... \n"
		grep $CURRENT -A $a $PFILE | grep $FACET #/dev/null 2>&1
		if [ $(echo $?) -eq 1 ]; then
			printf "environment $CURRENT in file $PFILE not contains facet named $FACET \n"
		else
			printf "environment $CURRENT in file $PFILE contains facet named $FACET \n"
			printf "replacing old ID to new ID named $ID ... \n"
			# number of line contain $FACET
			num=$(grep $CURRENT -n -A $a $PFILE | grep $FACET | cut -d- -f1)
			# replace line with old $ID in file $PFILE
			sed -i "$num s/\(.*\)$FACET/\t\t\"$ID/" $PFILE
			printf "Done... \n"
		fi
	else
		printf "environment named $CURRENT in file $PFILE contains same ID=$ID \n"
		printf "\n"
	fi
done

