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
elif [ "$mark" = "all" ] || [ "$mark" = "initiate-ios" ]; then
	if [ "$dest" = "STAGE" ]; then
		echo \[WARN_MARK\] branch name is \<b\>$BRANCHNAME\</b\>\<br\>dest is \<b\>$dest\</b\>\<br\>ID is \<b\>$ID\</b\>
	fi
	if [ "$dest" = "LIVE" ]; then
		echo \[WARN_MARK\] dest=LIVE, so just running on empty
	fi
	echo \[WARN_MARK\] branch name is \<b\>$BRANCHNAME\</b\>\<br\>dest is \<b\>$dest\</b\>\<br\>ID is \<b\>$ID\</b\>
elif ! [ "$mark"  = "all" ] || ! [ "$mark"  = "initiate-ios" ]; then
	echo \[WARN_MARK\] just running on empty
	exit 0
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
	if [ -z $1 ]; then
		echo "path to artifacts directory must be passed"
		exit 1
	fi
	function ssh_and_repack {
		TEMPORARY_IPA_REPACKING_DIR="~/tmp_repacking_ipa-$i"
		KEYSTORE="~/keystore_repacking_ipa/ipack.ks"
		STOREPASS="jenk123ins"
		KEYPASS="jenk123ins"
		ALIAS="jenkins-key"
		ssh dev02.design.isd.dp.ua "
		rm -rf $TEMPORARY_IPA_REPACKING_DIR
		mkdir $TEMPORARY_IPA_REPACKING_DIR
		mv ~/$BRANCH-FFA_Reader-$i.ipa $TEMPORARY_IPA_REPACKING_DIR/
		cd $TEMPORARY_IPA_REPACKING_DIR
		unzip $BRANCH-FFA_Reader-$i.ipa
		rm -f $BRANCH-FFA_Reader-$i.ipa
		if [ $ENVIRONMENT == current ]; then
			sed -i '1s@\(.*\)@{\n    \"currentURL\": \"https://wpps.isd.dp.ua/irls/$ENVIRONMENT/reader/$i/$BRANCH/client/dist/app/index.html\",@' Payload/$BRANCH-FFA_Reader-$i.app/www/dist/app/build.info.json
		elif [ $ENVIRONMENT == stage ]; then
			sed -i '2s@\(.*\)@    \"currentURL\": \"https://wpps.isd.dp.ua/irls/$ENVIRONMENT/reader/$i/$BRANCH/client/dist/app/index.html\",@' Payload/$BRANCH-FFA_Reader-$i.app/www/dist/app/build.info.json
		else
			exit 1
		fi
		java -jar /opt/ipack.jar $BRANCH-FFA_Reader-$i.ipa -keystore $KEYSTORE -storepass $STOREPASS -alias $ALIAS -keypass $KEYPASS -appdir Payload/$BRANCH-FFA_Reader-$i.app -appname $BRANCH-FFA_Reader-$i -appid \"UC7ZS26U3J.*\"
		"
	}
	# if path to artifacts directory contain word "stage" -> search ipa-files in artifacts directory for CURRENT-environment
	if [ -n "$(echo "$1" | grep stage)" ]; then
		echo contain stage;
		if [ ! -d $1 ]; then mkdir -p $1; fi
		find_stag=$(find $1 -name $BRANCH*FFA_Reader*$i.ipa) > /dev/null 2>&1
		if [ ! -z "$find_stag" ]; then
			echo "ipa file in $PWD exist" && echo "it is $find_stag"
			if unzip -c $find_stag | grep -q "currentURL"; then
				echo "Found URL inside ipa-file"
			else
				echo "NOT found URL inside ipa-file"
				scp $find_stag dev02.design.isd.dp.ua:~
				ENVIRONMENT="stage"
				ssh_and_repack
				scp dev02.design.isd.dp.ua:$TEMPORARY_IPA_REPACKING_DIR/$BRANCH-FFA_Reader-$i.ipa $1
				unzip -t -q $1$BRANCH-FFA_Reader-$i.ipa
			fi
		else
			echo "ipa file in $PWD not exists"
			find=$(find $2 -name $BRANCH*FFA_Reader*$i.ipa) > /dev/null 2>&1
			if [ ! -z "$find" ]; then
				echo PWD=$PWD
				#cp $find $PWD/ && echo "copying file $find to PWD=$PWD"
				scp $find dev02.design.isd.dp.ua:~
				ENVIRONMENT="stage"
				ssh_and_repack
				scp dev02.design.isd.dp.ua:$TEMPORARY_IPA_REPACKING_DIR/$BRANCH-FFA_Reader-$i.ipa $1
				unzip -t -q $1$BRANCH-FFA_Reader-$i.ipa
			fi
		fi
	else
		
		find=$(find $1 -name $BRANCH*FFA_Reader*$i.ipa) > /dev/null 2>&1
		if [ ! -z "$find" ]; then
			echo PWD=$PWD
			#cp $find $PWD/ && echo "copying file $find to PWD=$PWD"
			scp $find dev02.design.isd.dp.ua:~
			ENVIRONMENT="current"
			ssh_and_repack
			scp dev02.design.isd.dp.ua:$TEMPORARY_IPA_REPACKING_DIR/$BRANCH-FFA_Reader-$i.ipa $1
			unzip -t -q $1$BRANCH-FFA_Reader-$i.ipa
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
		# search ipa-files, if not exists - copy to artifacts dir
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
		INDEX_FILE='index_'$i'_'$BRANCH'.js'
		# output value for a pair "key-value"
		echo $i --- ${combineArray[$i]}
		# checking the existence of a directory with the artifacts
		if [ ! -d $ARTIFACTS_DIR ]; then
			mkdir -p $ARTIFACTS_DIR
		fi
		# search ipa-files, if not exists - copy to artifacts dir
		search_and_copy $STAGE_ARTIFACTS_DIR/ $CURRENT_ARTIFACTS_DIR/
		# generate index.html and local.json
		generate_files $PKG_DIR
		# run (re-run) node
		start_node $PKG_DIR $INDEX_FILE
		# update environment.json file
		/home/jenkins/scripts/search_for_environment.sh "${combineArray[$i]}" "$dest"
	done
elif [ "$dest" = "LIVE" ]; then
	exit 0
else
	printf "[ERROR_DEST] dest must be DEVELOPMENT or STAGE or LIVE! Not $dest! \n"
	exit 1
fi
