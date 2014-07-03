###
### Checking variables that were passed to the current bash-script
###
if [ -z $BRANCHNAME ]; then
    printf "[ERROR_BRANCHNAME] branchname must be passed! \n"
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
REMOTE_ART_PATH=/home/dvac/irls-reader-artifacts
LIVE_DIR=/home/jenkins/irls-reader-live
LIVE_LINKS_DIR=/home/jenkins/irls-reader-live-links
FACETS=($(echo $FACET))
# clean file myenv
cat /dev/null > $WORKSPACE/myenv
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
function generate_files {
	# $1 = $PKG_DIR ( or STAGE_PKG_DIR from STAGE-env )
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
	# $1=$PKG_DIR ( or STAGE_PKG_DIR from STAGE-env )
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
### If the variable $mark is equal to the value of "all" or "initiate-web", then perform the body of this script 
###
if [ "$mark" = "all" ] || [ "$mark" = "initiate-web" ]; then
	###
	### Body
	###
	if [ "$dest" = "DEVELOPMENT" ]; then
		for i in "${!combineArray[@]}"
		do
			# variables
			PKG_DIR=$CURRENT_ART_PATH/${combineArray[$i]}/packages
			INDEX_FILE='index_'$i'_'$BRANCH'.js'
			# output value for a pair "key-value"
			echo $i --- ${combineArray[$i]}
			# generate index.html and local.json
			generate_files $PKG_DIR
			# run (re-run) node
			start_node $PKG_DIR $INDEX_FILE
			# update environment.json file
			/home/jenkins/scripts/search_for_environment.sh "${combineArray[$i]}" "$dest"
			# generate links for description job
			echo link-$i-$dest="http://wpp.isd.dp.ua/irls/current/reader/$i/$BRANCH/client/dist/app/index.html" >> $WORKSPACE/myenv
			sed -i "s/link-$i-$dest/link$i/g" $WORKSPACE/myenv
		done
	elif [ "$dest" = "STAGE" ]; then
		for i in "${!combineArray[@]}"
		do
			# variables
			CURRENT_PKG_DIR=$CURRENT_ART_PATH/${combineArray[$i]}/packages
			STAGE_PKG_DIR=$STAGE_ART_PATH/${combineArray[$i]}/packages
			INDEX_FILE='index_'$i'_'$BRANCH'_'$dest'.js'
			# output value for a pair "key-value"
			echo $i --- ${combineArray[$i]}
			# copy files from CURRENT-env to STAGE-env
			cd $CURRENT_PKG_DIR
			if [ ! -d $STAGE_PKG_DIR ]; then
				mkdir -p $STAGE_PKG_DIR
				if [ -d common ] || [ -d client ] || [ -d server ] || [ -d couchdb_indexes ] || [ -d portal ]; then
					cp -Rf common client server couchdb_indexes artifacts portal $STAGE_PKG_DIR/
				fi
			else
				cd $STAGE_PKG_DIR
				rm -rf common client server couchdb_indexes artifacts portal
				rm -rf $STAGE_PKG_DIR/*
				cd $CURRENT_PKG_DIR
				# this check is needed because in the job named "irls-reader-initiate-web" was disabled facet named "ocean" 
				# ( to save time and because was next error:
				# "Unable to write "/var/lib/jenkins/jobs/irls-reader-initiate-web/workspace/packager/out/dest/develop-FFA_Reader-ocean-web-0.0.1/dist/app/epubs/thumbs/b6621f20d60938e3633132270bcfb263.png" file (Error code: ENOSPC).")
				# the reason is numbers of opened files ("ulimit -a" command) for user
				if [ -d common ] || [ -d client ] || [ -d server ] || [ -d couchdb_indexes ] || [ -d portal ]; then
					cp -Rf common client server couchdb_indexes artifacts portal $STAGE_PKG_DIR/
				fi
			fi
			# generate index.html and local.json
			generate_files $STAGE_PKG_DIR
			# run (re-run) node
			start_node $STAGE_PKG_DIR $INDEX_FILE
			# update environment.json file
			/home/jenkins/scripts/search_for_environment.sh "${combineArray[$i]}" "$dest"
			# generate links for description job
			echo link-$i-$dest="http://wpp.isd.dp.ua/irls/stage/reader/$i/$BRANCH/client/dist/app/index.html" >> $WORKSPACE/myenv
			sed -i "s/link-$i-$dest/link$i/g" $WORKSPACE/myenv
		done
	elif [ "$dest" = "LIVE" ]; then
		for i in "${!combineArray[@]}"
		do
			# values
			STAGE_PKG_DIR=$STAGE_ART_PATH/${combineArray[$i]}/packages
			# output value for a pair "key-value"
			echo $i --- ${combineArray[$i]}
			TGZ="IRLS.reader-$i\.tar.gz"
			ssh dvac@devzone.dp.ua "rm -f ~/$TGZ"
			tar -zc $STAGE_PKG_DIR/* | ssh dvac@devzone.dp.ua "cat > ~/$TGZ"
			ssh dvac@devzone.dp.ua "
				# values
				INDEX_FILE=index_"$i"_$BRANCH.js
				# check exist remote artifacts directory
				if [ ! -d  $REMOTE_ART_PATH/${combineArray[$i]} ]
				then
					mkdir -p $REMOTE_ART_PATH/${combineArray[$i]}
				else
					rm -rf  $REMOTE_ART_PATH/${combineArray[$i]}/packages/client $REMOTE_ART_PATH/${combineArray[$i]}/packages/common $REMOTE_ART_PATH/${combineArray[$i]}/packages/couchdb_indexes $REMOTE_ART_PATH/${combineArray[$i]}/packages/server 
				fi
				# upacking
				tar xfz $TGZ -C $REMOTE_ART_PATH/${combineArray[$i]}/
				if [ ! -d  $REMOTE_ART_PATH/${combineArray[$i]}/packages ]; then
					mkdir $REMOTE_ART_PATH/${combineArray[$i]}/packages
					mv $REMOTE_ART_PATH/${combineArray[$i]}$STAGE_PKG_DIR/* $REMOTE_ART_PATH/${combineArray[$i]}/packages/ && rm -rf $REMOTE_ART_PATH/${combineArray[$i]}/home
				else
					mv $REMOTE_ART_PATH/${combineArray[$i]}$STAGE_PKG_DIR/* $REMOTE_ART_PATH/${combineArray[$i]}/packages/ && rm -rf $REMOTE_ART_PATH/${combineArray[$i]}/home
				fi
				# Shorten path. Because otherwise - > Error of apache named AH00526 (ProxyPass worker name too long)
				if [ ! -d  $REMOTE_ART_PATH/${combineArray[$i]}/packages/art ]; then
					mkdir -p $REMOTE_ART_PATH/${combineArray[$i]}/packages/art
				fi
				mv $REMOTE_ART_PATH/${combineArray[$i]}/packages/artifacts/* $REMOTE_ART_PATH/${combineArray[$i]}/packages/art/
				/home/dvac/scripts/portgen-deploy-live.sh $BRANCH $i $dest ${combineArray[$i]}
				cp ~/local.json $REMOTE_ART_PATH/${combineArray[$i]}/packages/server/config
				#rm -rf /home/iogi/node/couchdb/var/lib/couchdb/*
				rm -rf /home/dvac/couchdb/var/lib/couchdb/*
				#cp -Rf $REMOTE_ART_PATH/${combineArray[$i]}/packages/couchdb_indexes/* /home/iogi/node/couchdb/var/lib/couchdb/
				cp -Rf $REMOTE_ART_PATH/${combineArray[$i]}/packages/couchdb_indexes/* /home/dvac/couchdb/var/lib/couchdb/
				
				cd $REMOTE_ART_PATH/${combineArray[$i]}/packages/
				PID=\$(ps aux | grep node.*server/\$INDEX_FILE | grep -v grep | /usr/bin/awk '{print \$2}')
				if [ ! -z \$PID ]
				then
					kill -9 \$PID
					nohup ~/node/bin/node server/\$INDEX_FILE > /dev/null 2>&1 &
				else
					nohup ~/node/bin/node server/\$INDEX_FILE > /dev/null 2>&1 &
				fi"
			# update environment.json file
			/home/jenkins/scripts/search_for_environment.sh "${combineArray[$i]}" "$dest"
			# generate links for description job
			echo link-$i-$dest="http://irls.websolutions.dp.ua/$i/$BRANCH/client/dist/app/index.html" >> $WORKSPACE/myenv
			sed -i "s/link-$i-$dest/link$i/g" $WORKSPACE/myenv
		done
	else
		printf "[ERROR_DEST] dest must be DEVELOPMENT or STAGE or LIVE! Not $dest! \n"
		exit 1
	fi
	# End of body
fi
