if [ -z $BRANCHNAME ]; then
    echo [ERROR_BRANCH] branchname must be passed!
    exit 1
fi

if [ "$mark" = "all" ] || [ "$mark" = "initiate-web" ]; then
	BUILD_ID=donotkillme
	ARTIFACTS_DIR=/home/jenkins/irls-reader-artifacts
	STAGE_DIR=/home/jenkins/irls-reader-artifacts-stage
	LIVE_DIR=/home/jenkins/irls-reader-live
	LIVE_LINKS_DIR=/home/jenkins/irls-reader-live-links
	FACETS=(puddle bahaiebooks lake ocean audio mediaoverlay)
	cat /dev/null > $WORKSPACE/myenv
	
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
	
	
	BRANCH=$(echo $BRANCHNAME | sed 's/\//-/g')
	if [ "$dest" = "DEVELOPMENT" ]; then
		for i in "${!combineArray[@]}"
		do
			# output value for a pair "key-value"
			echo $i --- ${combineArray[$i]}
			cd $ARTIFACTS_DIR/${combineArray[$i]}/packages
			INDEX_FILE='index_'$i'_'$BRANCH'.js'
			sudo /home/jenkins/scripts/portgenerator-for-deploy.sh $BRANCH $i $dest ${combineArray[$i]}
			cp local.json $ARTIFACTS_DIR/${combineArray[$i]}/packages/server/config
			if [ ! -f $ARTIFACTS_DIR/${combineArray[$i]}/packages/server/$INDEX_FILE ]; then
				if [ -f $ARTIFACTS_DIR/${combineArray[$i]}/packages/server/index.js ]; then
					mv server/index.js server/$INDEX_FILE
				else
					cp $(ls -1 server/index*.js | head -1) server/$INDEX_FILE
				fi	
			fi
			### Starting node server
			PID=$(ps aux | grep "node server/$INDEX_FILE" | grep -v grep | /usr/bin/awk '{print $2}')
			if [ ! -z "$PID" ];then
				kill $PID
				nohup node server/$INDEX_FILE > /dev/null 2>&1 &
			else
				nohup node server/$INDEX_FILE > /dev/null 2>&1 &
			fi
			echo link-$i="http://wpp.isd.dp.ua/irls/current/reader/$i/$BRANCH/client/dist/app/index.html" >> $WORKSPACE/myenv
			rm -f local.json irls-current-reader-$i-$BRANCH
		done
	elif [ "$dest" = "STAGE" ]; then
		for i in "${!combineArray[@]}"
		do
			# output value for a pair "key-value"
			echo $i --- ${combineArray[$i]}
			cd $ARTIFACTS_DIR/${combineArray[$i]}/packages
			if [ ! -d $STAGE_DIR/${combineArray[$i]} ]; then
				mkdir -p $STAGE_DIR/${combineArray[$i]}/packages
				cp -Rf common client server couchdb_indexes $STAGE_DIR/${combineArray[$i]}/packages/
			else
				cd $STAGE_DIR/${combineArray[$i]}/packages
				rm -rf common client server couchdb_indexes artifacts
				rm -rf $STAGE_DIR/${combineArray[$i]}/packages/*
				cd $ARTIFACTS_DIR/${combineArray[$i]}/packages
				cp -Rf common client server couchdb_indexes artifacts $STAGE_DIR/${combineArray[$i]}/packages
			fi
			cd $STAGE_DIR/${combineArray[$i]}/packages
			INDEX_FILE='index_'$i'_'$BRANCH'_'$dest'.js'
			sudo /home/jenkins/scripts/portgenerator-for-deploy.sh $BRANCH $i $dest ${combineArray[$i]}
			echo PWD=$PWD
			ls -lah
			cp local.json $STAGE_DIR/${combineArray[$i]}/packages/server/config
			if [ ! -f $STAGE_DIR/${combineArray[$i]}/packages/server/$INDEX_FILE ]; then
				if [ -f $STAGE_DIR/${combineArray[$i]}/packages/server/index.js ]; then
					mv server/index.js $STAGE_DIR/${combineArray[$i]}/packages/server/$INDEX_FILE
				else
					cp $(ls -1 server/index*.js | head -1) $STAGE_DIR/${combineArray[$i]}/packages/server/$INDEX_FILE
				fi	
			fi
			### Starting node server
			PID=$(ps aux | grep "node server/$INDEX_FILE" | grep -v grep | /usr/bin/awk '{print $2}')
			if [ ! -z "$PID" ];then
				kill $PID
				nohup node server/$INDEX_FILE > /dev/null 2>&1 &
			else
				nohup node server/$INDEX_FILE > /dev/null 2>&1 &
			fi
			echo link-$i-$dest="http://wpp.isd.dp.ua/irls/stage/reader/$i/$BRANCH/client/dist/app/index.html" >> $WORKSPACE/myenv
			rm -f local.json irls-current-reader-$i-$BRANCH
		done
	elif [ "$dest" = "LIVE" ]; then
		for i in "${!combineArray[@]}"
		do
			# output value for a pair "key-value"
			echo $i --- ${combineArray[$i]}
			ssh dvac@devzone.dp.ua "rm -f ~/IRLS.reader.tar.gz"
			tar -zc $STAGE_DIR/${combineArray[$i]}/packages/* | ssh dvac@devzone.dp.ua "cat > ~/IRLS.reader.tar.gz"
			ssh dvac@devzone.dp.ua "
				if [ ! -d  ~/irls-reader-artifacts/${combineArray[$i]} ]
				then
					mkdir ~/irls-reader-artifacts/${combineArray[$i]}
				else
					rm -rf  ~/irls-reader-artifacts/${combineArray[$i]}/packages/client ~/irls-reader-artifacts/${combineArray[$i]}/packages/common ~/irls-reader-artifacts/${combineArray[$i]}/packages/couchdb_indexes ~/irls-reader-artifacts/${combineArray[$i]}/packages/server 
				fi
				tar xfz IRLS.reader.tar.gz -C ~/irls-reader-artifacts/${combineArray[$i]}/
				if [ ! -d  ~/irls-reader-artifacts/${combineArray[$i]}/packages ]; then
					mkdir ~/irls-reader-artifacts/${combineArray[$i]}/packages
					mv ~/irls-reader-artifacts/${combineArray[$i]}$STAGE_DIR/${combineArray[$i]}/packages/* ~/irls-reader-artifacts/${combineArray[$i]}/packages/ && rm -rf ~/irls-reader-artifacts/${combineArray[$i]}/home
				else
					mv ~/irls-reader-artifacts/${combineArray[$i]}$STAGE_DIR/${combineArray[$i]}/packages/* ~/irls-reader-artifacts/${combineArray[$i]}/packages/ && rm -rf ~/irls-reader-artifacts/${combineArray[$i]}/home
				fi
				# Shorten path. Because otherwise - > Error of apache named AH00526 (ProxyPass worker name too long)
				if [ ! -d  ~/irls-reader-artifacts/${combineArray[$i]}/packages/art ]; then
					mkdir -p ~/irls-reader-artifacts/${combineArray[$i]}/packages/art
				fi
				mv ~/irls-reader-artifacts/${combineArray[$i]}/packages/artifacts/* ~/irls-reader-artifacts/${combineArray[$i]}/packages/art/
				/home/dvac/scripts/portgen-deploy-live.sh $BRANCH $i $dest ${combineArray[$i]}
				cp ~/local.json ~/irls-reader-artifacts/${combineArray[$i]}/packages/server/config
				rm -rf /home/iogi/node/couchdb/var/lib/couchdb/*
				cp -Rf ~/irls-reader-artifacts/${combineArray[$i]}/packages/couchdb_indexes/* /home/iogi/node/couchdb/var/lib/couchdb/
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
	
	
	LINKOCEAN=$(grep "link-ocean" $WORKSPACE/myenv | awk -F "=" '{print $2}')
	LINKLAKE=$(grep "link-lake" $WORKSPACE/myenv | awk -F "=" '{print $2}')
	LINKPUDDLE=$(grep "link-puddle" $WORKSPACE/myenv | awk -F "=" '{print $2}')
	LINKBAHAIE=$(grep "link-bahaiebooks" $WORKSPACE/myenv | awk -F "=" '{print $2}')
	echo LINKOCEAN=$LINKOCEAN >> $WORKSPACE/myenv
	echo LINKLAKE=$LINKLAKE >> $WORKSPACE/myenv
	echo LINKPUDDLE=$LINKPUDDLE >> $WORKSPACE/myenv
	echo LINKBAHAIE=$LINKBAHAIE >> $WORKSPACE/myenv
fi
