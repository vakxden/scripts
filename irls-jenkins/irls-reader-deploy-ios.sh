###
### Check of variable
###
if [ -z $BRANCHNAME ]; then
    echo "Branchname must be passed"
    exit 1
fi
if [ "$mark" = "all" ] || [ "$mark" = "initiate-ios" ]; then
	###
	### Variables
	###
	BUILD_ID=donotkillme
	ARTIFACTS_DIR=/home/jenkins/irls-reader-artifacts
	STAGE_DIR=/home/jenkins/irls-reader-artifacts-stage
	FACETS=(puddle bahaiebooks lake ocean audio)
	BRANCH=$(echo $BRANCHNAME | sed 's/\//-/g')
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
	### Body
	###
	if [ "$dest" = "DEVELOPMENT" ]; then
		for i in "${!combineArray[@]}"
	# search ipa-files, if not exists - copy to artifacts dir
		do
			echo $i --- ${combineArray[$i]}
			if [ ! -d $ARTIFACTS_DIR/${combineArray[$i]}/packages/artifacts ]; then
				mkdir -p $ARTIFACTS_DIR/${combineArray[$i]}/packages/artifacts
			fi
			DIR_IPA=/var/lib/jenkins/jobs/irls-reader-initiate-ios/builds/lastSuccessfulBuild/archive/
			ipa_file=$(find $DIR_IPA -name *$i*.ipa)
			if [ ! -f "$ipa_file" ]; then
				echo "ipa file $ipa_file in $DIR_IPA not exists"
			else
				echo "find ipa file $ipa_file"
				cp $ipa_file $ARTIFACTS_DIR/${combineArray[$i]}/packages/artifacts/
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
			# search ipa-files, if not exists - copy from artifacts dir to stage artifacts dir
			find_stag=$(find . -iregex '.*\(ipa\)' -printf '%f\n')
			if [ ! -z "$find_stag" ]; then
				echo "ipa file in $PWD exist" && echo "it is $find_stag"
			else
				echo "ipa file in $PWD not exists"
				find=$(find $ARTIFACTS_DIR/${combineArray[$i]}/packages/artifacts -iregex '.*\(ipa\)' -printf '%f\n')
				if [ ! -z "$find" ]; then
					echo $PWD
					cp $ARTIFACTS_DIR/${combineArray[$i]}/packages/artifacts/$find . && echo "copying file $find to $PWD"
				fi
			fi
			# generate index.html and local.json
			cd $STAGE_DIR/${combineArray[$i]}/packages
			INDEX_FILE='index_'$i'_'$BRANCH'_'$dest'.js'
			sudo /home/jenkins/scripts/portgenerator-for-deploy.sh $BRANCH $i $dest ${combineArray[$i]}
			rm -f $STAGE_DIR/${combineArray[$i]}/packages/server/config/local.json
			ls -lah
			echo PWD=$PWD
			if [ ! -d $STAGE_DIR/${combineArray[$i]}/packages/server/config ]; then
				mkdir -p $STAGE_DIR/${combineArray[$i]}/packages/server/config
			fi
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
					rm -rf  ~/irls-reader-artifacts/${combineArray[$i]}/packages/artifact/*.ipa
				fi"
			scp $ARTIFACTS_DIR/${combineArray[$i]}/packages/artifacts/*.ipa dvac@devzone.dp.ua:~/irls-reader-artifacts/${combineArray[$i]}/packages/artifact/
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
