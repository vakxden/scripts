###
### Checking variables that were passed to the current bash-script
###
if [ -z $BRANCHNAME ]; then
    printf "[ERROR_BRANCHNAME] Branchname must be passed \n"
    exit 1
fi
if [ -z $mark ]; then
    printf "[ERROR_MARK] mark must be passed \n"
    exit 1
fi
###
### Constant local variables
###
BRANCH=$(echo $BRANCHNAME | sed 's/\//-/g' | sed 's/_/-/g')
BUILD_ID=donotkillme
CURRENT_ART_PATH=/home/jenkins/irls-reader-artifacts
STAGE_ART_PATH=/home/jenkins/irls-reader-artifacts-stage
FACETS=($(echo $FACET))
###
### Create associative array
###
deploymentPackageId=($(echo $ID))
declare -A combineArray

for ((i=0; i<${#deploymentPackageId[@]}; i++))
do
	for ((y=0; y<${#FACETS[@]}; y++))
	do
		if [ -n "$(echo "${deploymentPackageId[i]}" | grep "${FACETS[y]}$")" ]; then
			combineArray+=(["${FACETS[y]}"]="${deploymentPackageId[i]}")
		fi
	done
done
###
### Functions
###
function search_and_copy {
	# $1=$STAGE_ARTIFACTS_DIR/
	# $2=$CURRENT_ARTIFACTS_DIR/
	printf "start of function search_and_copy \n"
	cd $1
	if [ -z $1 ]; then
		echo "path to artifacts directory must be passed"
		exit 1
	fi
	# if path to artifacts directory contain word "stage" -> search zip-files in artifacts directory for CURRENT-environment
	if [ -n "$(echo "$1" | grep stage)" ]; then
		echo "contain stage";
		find_stag=$(find $1 -name $BRANCH*FFA_Reader*$i-win*.zip) > /dev/null 2>&1
		if [ ! -z "$find_stag" ]; then
			echo "nw-win zip file in $PWD exist" && echo "it is $find_stag"
		else
			echo "nw-win zip file in $PWD not exists"
			find=$(find $2 -name $BRANCH*FFA_Reader*$i-win*.zip) > /dev/null 2>&1
			if [ ! -z "$find" ]; then
				cp -f $find $1 && echo "copying file $find to $1"
			fi
		fi
	fi
}
function generate_files {
	cd $1
	sudo /home/jenkins/scripts/portgenerator-for-deploy.sh $BRANCH $i $dest ${combineArray[$i]}
	#rm -f $1/server/config/local.json
	ls -lah
	echo PWD=$PWD
}
function pid_node {
	# $1 = $2 (server/$INDEX_FILE) from function start_node = $INDEX_FILE
	### Starting (or restarting) node server
		PID=$(ps aux | grep "node $1" | grep -v grep | /usr/bin/awk '{print $2}')
		if [ ! -z "$PID" ];then
			kill -9 $PID
			nohup node $1 > /dev/null 2>&1 &
		else
			nohup node $1 > /dev/null 2>&1 &
		fi
		rm -f local.json irls-current-reader-* irls-stage-reader-*
}
function start_node {
	# if content for running nodejs-server exists?
	# $1=$PKG_DIR
	# $2=$INDEX_FILE
	if [ -d $1/server/config ]; then
		cp -f local.json $1/server/config/
		if [ ! -f $1/server/$2 ]; then
			if [ -f $1/server/index.js ]; then
				mv server/index.js server/$2
				pid_node server/$2
			elif [ -f $1/server/index_*.js ]; then
					cp $(ls -1 server/index*.js | head -1) server/$2
					pid_node server/$2
			else
				echo "not found server/index.js in $1" && exit 0
			fi
		else
			pid_node server/$2
		fi
	fi
}
###
### If the variable $mark is equal to the value of "all" or "initiate-nw-win", then perform the body of this script 
###
if [ "$mark" = "all" ] || [ "$mark" = "initiate-nw-win" ]; then
	###
	### Body
	###
	if [ "$dest" = "DEVELOPMENT" ]; then
		for i in "${!combineArray[@]}"
		do
			# variables
			ARTIFACTS_DIR=$CURRENT_ART_PATH/${combineArray[$i]}/packages/artifacts
			PKG_DIR=$CURRENT_ART_PATH/${combineArray[$i]}/packages
			INDEX_FILE='index_'$i'_'$BRANCH'.js'
			# output value for a pair "key-value"
			echo $i --- ${combineArray[$i]}
			# checking the existence of a directory with the artifacts
			if [ ! -d $ARTIFACTS_DIR ]; then
				mkdir -p $ARTIFACTS_DIR
			fi
			# search node-webkit for Windows (nw-win) zip-files, if not exists - copy to artifacts dir
			search_and_copy $ARTIFACTS_DIR/
			# generate index.html and local.json
			generate_files $PKG_DIR
			# run (re-run) node
			start_node $PKG_DIR $INDEX_FILE
			# update environment.json file
			/home/jenkins/scripts/search_for_environment.sh "${combineArray[$i]}" "$dest"
		done
	elif [ "$dest" = "STAGE" ]; then
		for i in "${!combineArray[@]}"
		do
			# variables
			CURRENT_ARTIFACTS_DIR=$CURRENT_ART_PATH/${combineArray[$i]}/packages/artifacts
			STAGE_ARTIFACTS_DIR=$STAGE_ART_PATH/${combineArray[$i]}/packages/artifacts
			PKG_DIR=$STAGE_ART_PATH/${combineArray[$i]}/packages
			INDEX_FILE='index_'$i'_'$BRANCH'_'$dest'.js'
			# output value for a pair "key-value"
			echo $i --- ${combineArray[$i]}
			# checking the existence of a directory with the artifacts
			if [ ! -d $STAGE_ARTIFACTS_DIR ]; then
				mkdir -p $STAGE_ARTIFACTS_DIR
			fi
			# search node-webkit for Windows (nw-win) zip-files, if not exists - copy from artifacts dir to stage artifacts dir
			search_and_copy $STAGE_ARTIFACTS_DIR/ $CURRENT_ARTIFACTS_DIR/
			# generate index.html and local.json
			generate_files $PKG_DIR
			# run (re-run) node
			start_node $PKG_DIR $INDEX_FILE
			# update environment.json file
			/home/jenkins/scripts/search_for_environment.sh "${combineArray[$i]}" "$dest"
		done
	elif [ "$dest" = "LIVE" ]; then
		for i in "${!combineArray[@]}"
		do
			# output value for a pair "key-value"
			echo $i --- ${combineArray[$i]}
			ssh dvac@devzone.dp.ua "
				if [ ! -d  ~/irls-reader-artifacts/${combineArray[$i]}/packages/art ]
				then
					mkdir -p ~/irls-reader-artifacts/${combineArray[$i]}/packages/art
				else
					rm -rf  ~/irls-reader-artifacts/${combineArray[$i]}/packages/artifact/$BRANCH*FFA_Reader*$i-win*.zip
				fi"
			ARTIFACTS_DIR=$STAGE_ART_PATH/${combineArray[$i]}/packages/artifacts
			if [ -f $ARTIFACTS_DIR/$BRANCH*FFA_Reader*$i-win*.zip ]; then
				scp $ARTIFACTS_DIR/$BRANCH*FFA_Reader*$i-win*.zip dvac@devzone.dp.ua:~/irls-reader-artifacts/${combineArray[$i]}/packages/art/
			fi
			ssh dvac@devzone.dp.ua "
				/home/dvac/scripts/portgen-deploy-live.sh $BRANCH $i $dest ${combineArray[$i]}
				cp ~/local.json ~/irls-reader-artifacts/${combineArray[$i]}/packages/server/config
				INDEX_FILE=index_"$i"_$BRANCH.js
				cd ~/irls-reader-artifacts/${combineArray[$i]}/packages/
				PID=\$(ps aux | grep node.*server/\$INDEX_FILE | grep -v grep | /usr/bin/awk '{print \$2}')
				if [ ! -z \$PID ]
				then
					kill -9 \$PID
					nohup ~/node/bin/node server/\$INDEX_FILE > /dev/null 2>&1 &
				else
					nohup ~/node/bin/node server/\$INDEX_FILE > /dev/null 2>&1 &
				fi"
			echo link-$i-$dest="http://irls.websolutions.dp.ua/$i/$BRANCH/client/dist/app/index.html" >> $WORKSPACE/myenv
			# update environment.json file
			/home/jenkins/scripts/search_for_environment.sh "${combineArray[$i]}" "$dest"
		done
	else
		printf "[ERROR_DEST] dest must be DEVELOPMENT or STAGE or LIVE! Not $dest! \n"
		exit 1
	fi
fi
