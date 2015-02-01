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
elif [ "$mark" = "all" ] || [ "$mark" = "initiate-web" ]; then
        echo \[WARN_MARK\] branch name is \<b\>$BRANCHNAME\</b\>\<br\>ENVIRONMENT is \<b\>$ENVIRONMENT\</b\>\<br\>ID is \<b\>$ID\</b\>
elif ! [ "$mark"  = "all" ] || ! [ "$mark"  = "initiate-web" ]; then
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
REMOTE_ART_PATH=/home/dvac/irls-reader-artifacts
LIVE_DIR=/home/jenkins/irls-reader-live
LIVE_LINKS_DIR=/home/jenkins/irls-reader-live-links
TARGET=($(echo $TARGET))

# clean file myenv
cat /dev/null > $WORKSPACE/myenv

### Create associative array
deploymentPackageId=($(echo $ID))
printf "Array deploymentPackageId contain nexts elements:\n"
printf '%s\n' "${deploymentPackageId[@]}"

declare -A combineArray
for ((x=0; x<${#deploymentPackageId[@]}; x++))
do
        a=$(echo "${deploymentPackageId[x]}"| cut -d"_" -f 2-)
        combineArray+=(["$a"]="${deploymentPackageId[x]}")
done

printf "Associative array combineArray contains next key-value elements:\n"
for k in "${!combineArray[@]}"
do
        printf '%s\n' "key:$k -- value:${combineArray[$k]}"
done


###
### Functions
###
function generate_files {
        # $1 = $PKG_DIR ( or STAGE_PKG_DIR from STAGE-env )
        #cd $1
        sudo /home/jenkins/scripts/portgenerator-for-deploy.sh $BRANCH $i $ENVIRONMENT ${combineArray[$i]}
	#rm -f $1/server/config/local.json
	#cp -f local.json $1/server/config/
        #ls -lah
        #echo PWD=$PWD
}

function pid_node {
        # $1 = $2 (server/$INDEX_FILE) from function start_node = $INDEX_FILE
        ### Starting (or restarting) node server
                PID=$(ps aux | grep "node $1" | grep -v grep | /usr/bin/awk '{print $2}')
                if [ ! -z "$PID" ];then
                        kill -9 $PID
                        #nohup node $1 > /dev/null 2>&1 &
			if [ -f nohup.out ]; then cat /dev/null > nohup.out; fi
                        nohup node $1 >> nohup.out 2>&1 &
                else
                        #nohup node $1 > /dev/null 2>&1 &
			if [ -f nohup.out ]; then cat /dev/null > nohup.out; fi
                        nohup node $1 >> nohup.out 2>&1 &
                fi
                rm -f local.json irls-current-reader-* irls-stage-reader-*
}

function start_node {
        # if content for running nodejs-server exists?
        # $1=$PKG_DIR ( or STAGE_PKG_DIR from STAGE-env )
        # $2=$INDEX_FILE
        if [ -d $1/server/config ]; then
                if [ ! -f $1/server/$2 ]; then
                        if [ -f $1/server/index.js ]; then
                                mv server/index.js server/$2
                                pid_node server/$2
                        elif [ -f $1/server/index_*.js ]; then
                                        cp $(ls -1 $1/server/index*.js | head -1) $1/server/$2
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
if [ "$ENVIRONMENT" = "current" ]; then
        for i in "${!combineArray[@]}"
        do
                # variables
                PKG_DIR=$CURRENT_ART_PATH/${combineArray[$i]}/packages
                INDEX_FILE='index_'$i'_'$BRANCH'_'$ENVIRONMENT'.js'
                # output value for a pair "key-value"
                echo $i --- ${combineArray[$i]}
                # generate index.html and local.json
                generate_files $PKG_DIR
		# init users database
		cd $PKG_DIR
		if [ -f server/init.js ]; then
			node server/init.js
		fi
		# add URL for development environment
		if [ -f server/brandConfig.json ]; then
			NUM_OF_LINE=$(grep "brandUrl" server/brandConfig.json -n | awk -F ":" '{print $1}')
			sed -i "$NUM_OF_LINE""s#\"brandUrl.*#\"brandUrl\": \"https://wpps.isd.dp.ua/irls/current/reader/$i/$BRANCH/portal/\",#g" server/brandConfig.json
		fi
                # run (re-run) node
                start_node $PKG_DIR $INDEX_FILE
                # update environment.json file
                /home/jenkins/scripts/search_for_environment.sh "${combineArray[$i]}" "$ENVIRONMENT"
                # generate links for description job
                echo admin-link-$i-$ENVIRONMENT="https://wpps.isd.dp.ua/irls/current/reader/$i/$BRANCH/admin/dist/app/index_admin.html" >> $WORKSPACE/myenv
                echo editor-link-$i-$ENVIRONMENT="https://wpps.isd.dp.ua/irls/current/reader/$i/$BRANCH/editor/dist/app/index_editor.html" >> $WORKSPACE/myenv
                echo reader-link-$i-$ENVIRONMENT="https://wpps.isd.dp.ua/irls/current/reader/$i/$BRANCH/reader/dist/app/index_reader.html" >> $WORKSPACE/myenv
                echo portal-link-$i-$ENVIRONMENT="https://wpps.isd.dp.ua/irls/current/reader/$i/$BRANCH/portal/dist/app/index_portal.html" >> $WORKSPACE/myenv
        done
elif [ "$ENVIRONMENT" = "stage" ]; then
        for i in "${!combineArray[@]}"
        do
                # variables
                CURRENT_PKG_DIR=$CURRENT_ART_PATH/${combineArray[$i]}/packages
                STAGE_PKG_DIR=$STAGE_ART_PATH/${combineArray[$i]}/packages
                INDEX_FILE='index_'$i'_'$BRANCH'_'$ENVIRONMENT'.js'
                # output value for a pair "key-value"
                echo $i --- ${combineArray[$i]}
                # copy files from CURRENT-env to STAGE-env
                cd $CURRENT_PKG_DIR
                if [ ! -d $STAGE_PKG_DIR ]; then
                        mkdir -p $STAGE_PKG_DIR
                        time rsync -r --delete --exclude "*.ipa" --exclude "_oldjson" $CURRENT_PKG_DIR/ $STAGE_PKG_DIR/
                else
                        cd $STAGE_PKG_DIR
                        rm -rf common client server artifacts portal books
                        rm -rf $STAGE_PKG_DIR/*
                        cd $CURRENT_PKG_DIR
                        time rsync -r --delete --exclude "*.ipa" --exclude "_oldjson" $CURRENT_PKG_DIR/ $STAGE_PKG_DIR/
                fi
                # generate index.html and local.json
                generate_files $STAGE_PKG_DIR
		# init users database
		cd $STAGE_PKG_DIR
		if [ -f server/init.js ]; then
			node server/init.js
		fi
		# replace URL for stage environment
		if [ -f server/brandConfig.json ]; then
			NUM_OF_LINE=$(grep "brandUrl" server/brandConfig.json -n | awk -F ":" '{print $1}')
			sed -i "$NUM_OF_LINE""s#\"brandUrl.*#\"brandUrl\": \"https://wpps.isd.dp.ua/irls/stage/reader/$i/$BRANCH/portal/\",#g" server/brandConfig.json
		fi
                # run (re-run) node
                start_node $STAGE_PKG_DIR $INDEX_FILE
                # update environment.json file
                /home/jenkins/scripts/search_for_environment.sh "${combineArray[$i]}" "$ENVIRONMENT"
                # generate links for description job
                echo admin-link-$i-$ENVIRONMENT="https://wpps.isd.dp.ua/irls/stage/reader/$i/$BRANCH/admin/dist/app/index_admin.html" >> $WORKSPACE/myenv
                echo editor-link-$i-$ENVIRONMENT="https://wpps.isd.dp.ua/irls/stage/reader/$i/$BRANCH/editor/dist/app/index_editor.html" >> $WORKSPACE/myenv
                echo reader-link-$i-$ENVIRONMENT="https://wpps.isd.dp.ua/irls/stage/reader/$i/$BRANCH/reader/dist/app/index_reader.html" >> $WORKSPACE/myenv
                echo portal-link-$i-$ENVIRONMENT="https://wpps.isd.dp.ua/irls/stage/reader/$i/$BRANCH/portal/dist/app/index_portal.html" >> $WORKSPACE/myenv
        done
elif [ "$ENVIRONMENT" = "public" ]; then
        for i in "${!combineArray[@]}"
        do
                STAGE_PKG_DIR=$STAGE_ART_PATH/${combineArray[$i]}/packages
                RSYNC_FACETS_DIR="/home/dvac/rsync_facets/$i"
		# variables for product versioning
		#SPRINT=$(grep sprint $STAGE_PKG_DIR/client/dist/app/build.info.json | awk -F '"|"' '{print $4}')
		SPRINT=$(grep version $STAGE_PKG_DIR/package.json | awk -F '"|"' '{print $4}')
		BUILD_NUMBER=$(grep buildnumber $STAGE_PKG_DIR/client/dist/app/build.info.json | awk -F '"|"' '{print $4}')
		BUILD_DATE=$(grep builddate $STAGE_PKG_DIR/client/dist/app/build.info.json | awk -F '"|"' '{print $4}' | sed -e 's#(#\\(#g' -e 's#)#\\)#g')
		BUILD_VERSION_JSON="/home/dvac/apache2/var/www/portal/build.version.json"
                ssh dvac@devzone.dp.ua "if [ ! -d $RSYNC_FACETS_DIR ]; then mkdir -p $RSYNC_FACETS_DIR; fi"
                ssh dvac@devzone.dp.ua "
			rm -f $RSYNC_FACETS_DIR/client/dist/app/epubs/dirstructure.json
                        if [ ! -d  $REMOTE_ART_PATH/${combineArray[$i]} ]; then mkdir -p $REMOTE_ART_PATH/${combineArray[$i]}; fi
			# create of status-deploy file
			if [ ! -e $REMOTE_ART_PATH/${combineArray[$i]}/status_deploy.txt ]; then touch $REMOTE_ART_PATH/${combineArray[$i]}/status_deploy.txt; fi"
                time rsync -rz --delete --exclude "*.ipa" --exclude "_oldjson" -e "ssh" $STAGE_PKG_DIR/ dvac@devzone.dp.ua:$RSYNC_FACETS_DIR/
                ssh dvac@devzone.dp.ua "
                        # values
                	INDEX_FILE='index_'$i'_'$BRANCH'_'$ENVIRONMENT'.js'
			# copying files from RSYNC_FACETS_DIR to REMOTE_ART_PATH/{combineArray[i]}
                        cp -Rf $RSYNC_FACETS_DIR/* $REMOTE_ART_PATH/${combineArray[$i]}/
                        # Shorten path. Because otherwise - > Error of apache named AH00526 (ProxyPass worker name too long)
                        if [ ! -d  $REMOTE_ART_PATH/${combineArray[$i]}/art ]; then
                                mkdir -p $REMOTE_ART_PATH/${combineArray[$i]}/art
                        fi
                        #mv $REMOTE_ART_PATH/${combineArray[$i]}/artifacts $REMOTE_ART_PATH/${combineArray[$i]}/art
                        /home/dvac/scripts/portgen-deploy-live.sh $BRANCH $i $ENVIRONMENT ${combineArray[$i]}
                        cp ~/local.json $REMOTE_ART_PATH/${combineArray[$i]}/server/config
			# init users database
			cd $REMOTE_ART_PATH/${combineArray[$i]}
			if [ -f server/init.js ]; then
				~/node/bin/node server/init.js
			fi
			# replace URL for live environment
			if [ -f server/brandConfig.json ]; then
				sed -i 's#\"brandUrl.*#\"brandUrl\": \"https://irls.isd.dp.ua/$i/$BRANCH/portal/\",#g' server/brandConfig.json
			fi
                        # Start node
                        cd $REMOTE_ART_PATH/${combineArray[$i]}
			# number of version line
			NUMBER_OF_VERSION_LINE=\$(grep '\"$i\"' $BUILD_VERSION_JSON -A3 -n | grep version | awk -F '-' '{print \$1}')
			echo NUMBER_OF_VERSION_LINE=\$NUMBER_OF_VERSION_LINE
			# replace version for $i target
			if [ $i == ffa ] || [ $i == ocean ] || [ $i == irls-ocean ] || [ $i == irls-epubtest ]; then
				eval sed -i \$NUMBER_OF_VERSION_LINE\\\"s#'\'\\\"version.*#'\'\\\"version'\'\\\":'\'\\\"$SPRINT\.$BUILD_NUMBER-dev'\'\\\",#g\\\" $BUILD_VERSION_JSON
			else
				eval sed -i \$NUMBER_OF_VERSION_LINE\\\"s#'\'\\\"version.*#'\'\\\"version'\'\\\":'\'\\\"$SPRINT\.$BUILD_NUMBER'\'\\\",#g\\\" $BUILD_VERSION_JSON
			fi
			## number of build date time
			NUMBER_OF_BUILD_DATE_TIME=\$(grep '\"$i\"' $BUILD_VERSION_JSON -A3 -n | grep buildDateTime | awk -F '-' '{print \$1}')
			echo NUMBER_OF_BUILD_DATE_TIME=\$NUMBER_OF_BUILD_DATE_TIME
			## replace build date time for $i target
			eval sed -i \$NUMBER_OF_BUILD_DATE_TIME\\\"s#'\'\\\"buildDateTime.*#'\'\\\"buildDateTime'\'\\\":'\'\\\"$BUILD_DATE'\'\\\"#g\\\" $BUILD_VERSION_JSON
                        PID=\$(ps aux | grep node.*server/\$INDEX_FILE | grep -v grep | /usr/bin/awk '{print \$2}')
                        if [ ! -z \$PID ]
                        then
                                kill -9 \$PID
				if [ -f nohup.out ]; then cat /dev/null > nohup.out; fi
				nohup ~/node/bin/node server/\$INDEX_FILE >> nohup.out 2>&1 &
                        else
				nohup ~/node/bin/node server/\$INDEX_FILE >> nohup.out 2>&1 &
				if [ -f nohup.out ]; then cat /dev/null > nohup.out; fi
                        fi
			sleep 5
			rm -f $REMOTE_ART_PATH/${combineArray[$i]}/status_deploy.txt"
                # update environment.json file
                /home/jenkins/scripts/search_for_environment.sh "${combineArray[$i]}" "$ENVIRONMENT"
                # generate links for description job
                echo admin-link-$i-$ENVIRONMENT="https://irls.isd.dp.ua/$i/$BRANCH/admin/dist/app/index_admin.html" >> $WORKSPACE/myenv
                echo editor-link-$i-$ENVIRONMENT="https://irls.isd.dp.ua/$i/$BRANCH/editor/dist/app/index_editor.html" >> $WORKSPACE/myenv
                echo reader-link-$i-$ENVIRONMENT="https://irls.isd.dp.ua/$i/$BRANCH/reader/dist/app/index_reader.html" >> $WORKSPACE/myenv
                echo portal-link-$i-$ENVIRONMENT="https://irls.isd.dp.ua/$i/$BRANCH/portal/dist/app/index_portal.html" >> $WORKSPACE/myenv
                sed -i "s/link-$i-$ENVIRONMENT/link$i/g" $WORKSPACE/myenv
        done
else
        printf "[ERROR_DEST] ENVIRONMENT must be current or stage or public! Not $ENVIRONMENT! \n"
        exit 1
fi
