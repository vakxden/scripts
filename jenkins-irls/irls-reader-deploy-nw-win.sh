###
### Checking variables that were passed to the current bash-script
###
if [ -z $BRANCHNAME ]; then
    echo "Branchname must be passed"
    exit 1
fi
if [ -z $mark ]; then
    echo "mark must be passed"
    exit 1
fi
###
### Constant local variables
###
BUILD_ID=donotkillme
ARTIFACTS_DIR=/home/jenkins/irls-reader-artifacts
STAGE_DIR=/home/jenkins/irls-reader-artifacts-stage
FACETS=(puddle bahaiebooks lake ocean audio)
BRANCH=$(echo $BRANCHNAME | sed 's/\//-/g')
DIR_ZIP=/var/lib/jenkins/jobs/irls-reader-initiate-nw-win/builds/lastSuccessfulBuild/archive/
###
### Create associative array
###
deploymentPackageId=($(echo $ID))
declare -A combineArray

for ((i=0; i<${#deploymentPackageId[@]}; i++))
do
	for ((y=0; y<${#FACETS[@]}; y++))
	do
		if [ -n "$(echo "${deploymentPackageId[i]}" | grep "${FACETS[y]}")" ]; then
			combineArray+=(["${FACETS[y]}"]="${deploymentPackageId[i]}")
		fi
	done
done
###
### If the variable $mark is equal to the value of "all" or "initiate-nw-win", then perform the body of this script 
###
if [ "$mark" = "all" ] || [ "$mark" = "initiate-nw-win" ]; then
	###
	### Body
	###
	if [ "$dest" = "DEVELOPMENT" ]; then
		for i in "${!combineArray[@]}"
	# search node-webkit for Windows (nw-win) zip-files, if not exists - copy to artifacts dir
		do
			echo $i --- ${combineArray[$i]}
			if [ ! -d $ARTIFACTS_DIR/${combineArray[$i]}/packages/artifacts ]; then
				mkdir -p $ARTIFACTS_DIR/${combineArray[$i]}/packages/artifacts
			fi
			zip_file=$(find $DIR_ZIP -name *$i-win*.zip)
			if [ ! -f "$zip_file" ]; then
				echo "nw-win zip file $zip_file in $DIR_ZIP not exists"
			else
				echo "find nw-win zip-file $zip_file"
				cp $zip_file $ARTIFACTS_DIR/${combineArray[$i]}/packages/artifacts/
			fi
			# generate index.html and local.json
			cd $ARTIFACTS_DIR/${combineArray[$i]}/packages
			INDEX_FILE='index_'$i'_'$BRANCH'.js'
			sudo /home/jenkins/scripts/portgenerator-for-deploy.sh $BRANCH $i $dest ${combineArray[$i]}
			rm -f $ARTIFACTS_DIR/${combineArray[$i]}/packages/server/config/local.json
			ls -lah
			echo PWD=$PWD
			# if content for running nodejs-server exists?
			if [ -d $ARTIFACTS_DIR/${combineArray[$i]}/packages/server/config ]; then
				cp local.json $ARTIFACTS_DIR/${combineArray[$i]}/packages/server/config/
				if [ ! -f $ARTIFACTS_DIR/${combineArray[$i]}/packages/server/$INDEX_FILE ]; then
					if [ -f $ARTIFACTS_DIR/${combineArray[$i]}/packages/server/index.js ]; then
						mv server/index.js server/$INDEX_FILE
					else
						cp $(ls -1 server/index*.js | head -1) server/$INDEX_FILE
					fi	
				fi
				### Starting (or restarting) node server
				PID=$(ps aux | grep "node server/$INDEX_FILE" | grep -v grep | /usr/bin/awk '{print $2}')
				if [ ! -z "$PID" ];then
					kill $PID
					nohup node server/$INDEX_FILE > /dev/null 2>&1 &
				else
					nohup node server/$INDEX_FILE > /dev/null 2>&1 &
				fi
				rm -f local.json irls-current-reader-$i-$BRANCH
			fi
		done
	elif [ "$dest" = "STAGE" ]; then
		for i in "${!combineArray[@]}"
		do
			echo $i --- ${combineArray[$i]}
			if [ ! -d $STAGE_DIR/${combineArray[$i]}/packages/artifacts ]; then
						mkdir -p $STAGE_DIR/${combineArray[$i]}/packages/artifacts
					fi
			cd $STAGE_DIR/${combineArray[$i]}/packages/artifacts
			# search node-webkit for Windows (nw-win) zip-files,, if not exists - copy from artifacts dir to stage artifacts dir
			find_stag=$(find . -name *$i-win*.zip)
			if [ ! -z "$find_stag" ]; then
				echo "nw-win zip file in $PWD exist" && echo "it is $find_stag"
			else
				echo "nw-win zip file in $PWD not exists"
				find=$(find $ARTIFACTS_DIR/${combineArray[$i]}/packages/artifacts -name *$i-win*.zip)
				if [ ! -z "$find" ]; then
					echo PWD=$PWD
					cp $find $PWD/ && echo "copying file $find to PWD=$PWD"
				fi
			fi
			# generate index.html and local.json
			cd $STAGE_DIR/${combineArray[$i]}/packages
			INDEX_FILE='index_'$i'_'$BRANCH'_'$dest'.js'
			sudo /home/jenkins/scripts/portgenerator-for-deploy.sh $BRANCH $i $dest ${combineArray[$i]}
			rm -f $STAGE_DIR/${combineArray[$i]}/packages/server/config/local.json
			ls -lah
			echo PWD=$PWD
			# if content for running nodejs-server exists?
			if [ -d $STAGE_DIR/${combineArray[$i]}/packages/server/config ]; then
				cp local.json $STAGE_DIR/${combineArray[$i]}/packages/server/config/
				if [ ! -f $STAGE_DIR/${combineArray[$i]}/packages/server/$INDEX_FILE ]; then
					if [ -f $STAGE_DIR/${combineArray[$i]}/packages/server/index.js ]; then
						mv server/index.js server/$INDEX_FILE
					else
						cp $(ls -1 server/index*.js | head -1) server/$INDEX_FILE
					fi	
				fi
				### Starting (or restarting) node server
				PID=$(ps aux | grep "node server/$INDEX_FILE" | grep -v grep | /usr/bin/awk '{print $2}')
				if [ ! -z "$PID" ];then
					kill $PID
					nohup node server/$INDEX_FILE > /dev/null 2>&1 &
				else
					nohup node server/$INDEX_FILE > /dev/null 2>&1 &
				fi
				rm -f local.json
			fi
		done
	elif [ "$dest" = "LIVE" ]; then
		for i in "${!combineArray[@]}"
		do
			echo $i --- ${combineArray[$i]}
			ssh dvac@devzone.dp.ua "
				if [ ! -d  ~/irls-reader-artifacts/${combineArray[$i]}/packages/artifact ]
				then
					mkdir -p ~/irls-reader-artifacts/${combineArray[$i]}/packages/artifact
				else
					rm -rf  ~/irls-reader-artifacts/${combineArray[$i]}/packages/artifact/*\$i-win*.zip
				fi"
			scp $ARTIFACTS_DIR/${combineArray[$i]}/packages/artifacts/*$i-win*.zip dvac@devzone.dp.ua:~/irls-reader-artifacts/${combineArray[$i]}/packages/artifact/
			ssh dvac@devzone.dp.ua "
				/home/dvac/scripts/portgen-deploy-live.sh $BRANCH $i $dest ${combineArray[$i]}
				cp ~/local.json ~/irls-reader-artifacts/${combineArray[$i]}/packages/server/config
				INDEX_FILE=index_"$i"_$BRANCH.js
				cd ~/irls-reader-artifacts/${combineArray[$i]}/packages/
				PID=\$(ps aux | grep node.*server/\$INDEX_FILE | grep -v grep | /usr/bin/awk '{print \$2}')
				if [ ! -z \$PID ]
				then
					kill \$PID
					nohup ~/node/bin/node server/\$INDEX_FILE > /dev/null 2>&1 &
				else
					nohup ~/node/bin/node server/\$INDEX_FILE > /dev/null 2>&1 &
				fi"
				echo link-$i-$dest="http://irls.websolutions.dp.ua/$i/$BRANCH/client/dist/app/index.html" >> $WORKSPACE/myenv
		done
	else
		echo [ERROR_DEST] dest must be DEVELOPMENT or STAGE or LIVE! Not $dest!
		exit 1
	fi
fi
