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
                echo \[WARN_MARK\] branch name is \<b\>$BRANCHNAME\</b\>\<br\>dest is \<b\>$dest\</b\>\<br\>ID is \<b\>$ID\</b\>
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
TARGET=($(echo $TARGET))

###
### Create associative array
###
deploymentPackageId=($(echo $ID))
declare -A combineArray

for ((i=0; i<${#deploymentPackageId[@]}; i++))
do
	a=$(echo "${deploymentPackageId[i]}"| cut -d"_" -f 2-)
	combineArray+=(["$a"]="${deploymentPackageId[i]}")
        #for ((y=0; y<${#TARGET[@]}; y++))
        #do
                #if [ -n "$(echo "${deploymentPackageId[i]}" | grep "${TARGET[y]}$")" ]; then
                        #combineArray+=(["${TARGET[y]}"]="${deploymentPackageId[i]}")
                #fi
        #done
done

###
### Functions
###
function ssh_and_repack {
        KEYSTORE="~/keystore_repacking_ipa/ipack.ks"
        STOREPASS="jenk123ins"
        KEYPASS="jenk123ins"
        ALIAS="jenkins-key"
        if [ $ENVIRONMENT == current ] || [ $ENVIRONMENT == stage ]; then
                CURRENT_URL="https://wpps.isd.dp.ua/irls/$ENVIRONMENT/reader/$i/$BRANCH/"
        elif [ $ENVIRONMENT == live ]; then
                CURRENT_URL="https://irls.isd.dp.ua/$i/$BRANCH/"
        fi
        ssh dev02.design.isd.dp.ua "
        rm -rf $TEMPORARY_IPA_REPACKING_DIR
        mkdir $TEMPORARY_IPA_REPACKING_DIR
        mv ~/$IPA_FILE_NAME $TEMPORARY_IPA_REPACKING_DIR/
        cd $TEMPORARY_IPA_REPACKING_DIR
        unzip $IPA_FILE_NAME
        rm -f $IPA_FILE_NAME
        if [ $ENVIRONMENT == current ]; then
                sed -i '1s@\(.*\)@{\n    \"currentURL\": \"$CURRENT_URL\",@' Payload/$IPA_NAME.app/www/dist/app/build.info.json
        elif [ $ENVIRONMENT == stage ]; then
                sed -i '2s@\(.*\)@    \"currentURL\": \"$CURRENT_URL\",@' Payload/$IPA_NAME.app/www/dist/app/build.info.json
        elif [ $ENVIRONMENT == live ]; then
                sed -i '2s@\(.*\)@    \"currentURL\": \"$CURRENT_URL\",@' Payload/$IPA_NAME.app/www/dist/app/build.info.json
        else
                exit 1
        fi
        java -jar /opt/ipack.jar $IPA_FILE_NAME -keystore $KEYSTORE -storepass $STOREPASS -alias $ALIAS -keypass $KEYPASS -appdir Payload/$IPA_NAME.app -appname $IPA_NAME -appid \"UC7ZS26U3J.*\"
        "
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
        # $1 = CURRENT_ or STAGE_ PKG_DIR
        # $2 = $INDEX_FILE
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
                # output value for a pair "key-value"
                echo $i --- ${combineArray[$i]}
                # variables
                CURRENT_ARTIFACTS_DIR=$CURRENT_ART_PATH/${combineArray[$i]}/packages/artifacts
                CURRENT_PKG_DIR=$CURRENT_ART_PATH/${combineArray[$i]}/packages
                INDEX_FILE='index_'$i'_'$BRANCH'.js'
                ENVIRONMENT="current"
		TARGETS_REPO="git@wpp.isd.dp.ua:irls/targets.git"
		TARGETS_REPO_DIR_NAME=$(echo $TARGETS_REPO | cut -d":" -f2 | cut -d"/" -f2 | sed s@.git@@g)
		### Clone or "git pull" (if exist) targets-repo
		if [ ! -d $WORKSPACE/$TARGETS_REPO_DIR_NAME ]; then
			cd $WORKSPACE && git clone $TARGETS_REPO
		else
			cd $WORKSPACE/$TARGETS_REPO_DIR_NAME && git pull
		fi
		BRAND=$(grep brand $WORKSPACE/targets/$i/targetConfig.json | awk -F '"|"' '{print $4}')
		### Checking contain platform
                if grep "platforms.*ios" $WORKSPACE/targets/$i/targetConfig.json; then
			IPA_NAME=$(echo $BRANCH-"$BRAND"_Reader-$i)
			IPA_FILE_NAME="$IPA_NAME.ipa"
                	TEMPORARY_IPA_REPACKING_DIR="~/tmp_repacking_ipa-$i"
	                # checking the existence of a directory with the artifacts
	                if [ ! -d $CURRENT_ARTIFACTS_DIR ]; then mkdir -p $CURRENT_ARTIFACTS_DIR; fi
	                # search ipa-file and repacking it
	                find $CURRENT_ARTIFACTS_DIR -name $IPA_FILE_NAME -exec scp {} dev02.design.isd.dp.ua:~ \;
	                ssh_and_repack
	                scp dev02.design.isd.dp.ua:$TEMPORARY_IPA_REPACKING_DIR/$IPA_FILE_NAME $CURRENT_ARTIFACTS_DIR/
	                # test archive (ipa) file
	                unzip -t -q $CURRENT_ARTIFACTS_DIR/$IPA_FILE_NAME
	                # generate index.html and local.json
	                generate_files $CURRENT_PKG_DIR
	                # run (re-run) node
	                start_node $CURRENT_PKG_DIR $INDEX_FILE
	                # update environment.json file
	                /home/jenkins/scripts/search_for_environment.sh "${combineArray[$i]}" "$dest"
                else
                        echo "Shutdown of this job because platform \"ios\" not found in config targetConfig.json"
			echo \[WARN_MARK\] just running on empty for $i
                        exit 0
                fi
        done
elif [ "$dest" = "STAGE" ]; then
        for i in "${!combineArray[@]}"
        do
                # output value for a pair "key-value"
                echo $i --- ${combineArray[$i]}
                # variables
                CURRENT_ARTIFACTS_DIR=$CURRENT_ART_PATH/${combineArray[$i]}/packages/artifacts
                STAGE_ARTIFACTS_DIR=$STAGE_ART_PATH/${combineArray[$i]}/packages/artifacts
                STAGE_PKG_DIR=$STAGE_ART_PATH/${combineArray[$i]}/packages
                INDEX_FILE='index_'$i'_'$BRANCH'_'$dest'.js'
                ENVIRONMENT="stage"
		TARGETS_REPO="git@wpp.isd.dp.ua:irls/targets.git"
		TARGETS_REPO_DIR_NAME=$(echo $TARGETS_REPO | cut -d":" -f2 | cut -d"/" -f2 | sed s@.git@@g)
		### Clone or "git pull" (if exist) targets-repo
		if [ ! -d $WORKSPACE/$TARGETS_REPO_DIR_NAME ]; then
			cd $WORKSPACE && git clone $TARGETS_REPO
		else
			cd $WORKSPACE/$TARGETS_REPO_DIR_NAME && git pull
		fi
		BRAND=$(grep brand $WORKSPACE/targets/$i/targetConfig.json | awk -F '"|"' '{print $4}')
		### Checking contain platform
                if grep "platforms.*ios" $WORKSPACE/targets/$i/targetConfig.json; then
			IPA_NAME=$(echo $BRANCH-"$BRAND"_Reader-$i)
			IPA_FILE_NAME="$IPA_NAME.ipa"
	                TEMPORARY_IPA_REPACKING_DIR="~/tmp_repacking_ipa-$i"
	                # checking the existence of a directory with the artifacts
	                if [ ! -d $CURRENT_ARTIFACTS_DIR ]; then mkdir -p $CURRENT_ARTIFACTS_DIR; fi
	                if [ ! -d $STAGE_ARTIFACTS_DIR ]; then mkdir -p $STAGE_ARTIFACTS_DIR; fi
	                # copying ipa-file from CURRENT_ARTIFACTS_DIR to STAGE_ARTIFACTS_DIR and repacking it
	                rm -f $STAGE_ARTIFACTS_DIR/$IPA_FILE_NAME
	                find $CURRENT_ARTIFACTS_DIR -name $IPA_FILE_NAME -exec scp {} dev02.design.isd.dp.ua:~ \;
	                ssh_and_repack
	                scp dev02.design.isd.dp.ua:$TEMPORARY_IPA_REPACKING_DIR/$IPA_FILE_NAME $STAGE_ARTIFACTS_DIR/
	                # test archive (ipa) file
	                unzip -t -q $STAGE_ARTIFACTS_DIR/$IPA_FILE_NAME
	                # generate index.html and local.json
	                generate_files $STAGE_PKG_DIR
	                # run (re-run) node
	                start_node $STAGE_PKG_DIR $INDEX_FILE
	                # update environment.json file
	                /home/jenkins/scripts/search_for_environment.sh "${combineArray[$i]}" "$dest"
                else
                        echo "Shutdown of this job because platform \"ios\" not found in config targetConfig.json"
			echo \[WARN_MARK\] just running on empty for $i
                        exit 0
                fi
        done
elif [ "$dest" = "LIVE" ]; then
        for i in "${!combineArray[@]}"
        do
                # output value for a pair "key-value"
                echo $i --- ${combineArray[$i]}
                # variables
                STAGE_ARTIFACTS_DIR=$STAGE_ART_PATH/${combineArray[$i]}/packages/artifacts
                REMOTE_ART_PATH="/home/dvac/irls-reader-artifacts"
                LIVE_ARTIFACTS_DIR="$REMOTE_ART_PATH/${combineArray[$i]}/art"
                INDEX_FILE='index_'$i'_'$BRANCH'.js'
                TEMPORARY_IPA_REPACKING_DIR="~/tmp_repacking_ipa-$i"
                ENVIRONMENT="live"
		TARGETS_REPO="git@wpp.isd.dp.ua:irls/targets.git"
		TARGETS_REPO_DIR_NAME=$(echo $TARGETS_REPO | cut -d":" -f2 | cut -d"/" -f2 | sed s@.git@@g)
		### Clone or "git pull" (if exist) targets-repo
		if [ ! -d $WORKSPACE/$TARGETS_REPO_DIR_NAME ]; then
			cd $WORKSPACE && git clone $TARGETS_REPO
		else
			cd $WORKSPACE/$TARGETS_REPO_DIR_NAME && git pull
		fi
		BRAND=$(grep brand $WORKSPACE/targets/$i/targetConfig.json | awk -F '"|"' '{print $4}')
		### Checking contain platform
                if grep "platforms.*ios" $WORKSPACE/targets/$i/targetConfig.json; then
			IPA_NAME=$(echo $BRANCH-"$BRAND"_Reader-$i)
			IPA_FILE_NAME="$IPA_NAME.ipa"
	                # copying ipa-file from STAGE_ARTIFACTS_DIR to devzone and repacking it
	                find $STAGE_ARTIFACTS_DIR -name $IPA_FILE_NAME -exec scp {} dev02.design.isd.dp.ua:~ \;
	                ssh_and_repack
	                rm -f $WORKSPACE/$IPA_FILE_NAME
	                scp dev02.design.isd.dp.ua:$TEMPORARY_IPA_REPACKING_DIR/$IPA_FILE_NAME $WORKSPACE/
	                # test archive (ipa) file
	                unzip -t -q $WORKSPACE/$IPA_FILE_NAME
	                # checking the existence of a directory with the artifacts
	                ssh dvac@devzone.dp.ua "if [ ! -d $LIVE_ARTIFACTS_DIR ]; then mkdir -p $LIVE_ARTIFACTS_DIR; fi"
	                scp $WORKSPACE/$IPA_FILE_NAME dvac@devzone.dp.ua:$LIVE_ARTIFACTS_DIR/
	                ssh dvac@devzone.dp.ua "
	                        # values
	                        if [ ! -d  $REMOTE_ART_PATH/${combineArray[$i]} ]; then mkdir -p $REMOTE_ART_PATH/${combineArray[$i]}; fi
	                        # Shorten path. Because otherwise - > Error of apache named AH00526 (ProxyPass worker name too long)
	                        if [ ! -d  $LIVE_ARTIFACTS_DIR ]; then mkdir -p $LIVE_ARTIFACTS_DIR; fi
	                        /home/dvac/scripts/portgen-deploy-live.sh $BRANCH $i $dest ${combineArray[$i]}
	                        cp ~/local.json $REMOTE_ART_PATH/${combineArray[$i]}/server/config
	                        # Start node
	                        cd $REMOTE_ART_PATH/${combineArray[$i]}
	                        PID=\$(ps aux | grep node.*server/$INDEX_FILE | grep -v grep | /usr/bin/awk '{print \$2}')
	                        if [ ! -z \$PID ]
	                        then
	                                kill -9 \$PID
	                                nohup ~/node/bin/node server/$INDEX_FILE > /dev/null 2>&1 &
	                        else
	                                nohup ~/node/bin/node server/$INDEX_FILE > /dev/null 2>&1 &
	                        fi"
	                # update environment.json file
	                /home/jenkins/scripts/search_for_environment.sh "${combineArray[$i]}" "$dest"
	                rm -f $WORKSPACE/$IPA_FILE_NAME
                else
                        echo "Shutdown of this job because platform \"ios\" not found in config targetConfig.json"
			echo \[WARN_MARK\] just running on empty for $i
                        exit 0
                fi
        done
else
        printf "[ERROR_DEST] dest must be DEVELOPMENT or STAGE or LIVE! Not $dest! \n"
        exit 1
fi
