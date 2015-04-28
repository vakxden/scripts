# This script executes on the remote host named dev02.design.isd.dp.ua

###
### Checking variables that were passed to the current script
###
ARRAY_OF_ENVIRONMENTS=(current stage public) #an array that contains the correct names of environments
containsElement () {
        local e
        for e in "${@:2}"; do [[ "$e" == "$1" ]] && return 0; done
        return 1
        }
if ! $(containsElement "$ENVIRONMENT" "${ARRAY_OF_ENVIRONMENTS[@]}"); then printf "[ERROR_DEST] ENVIRONMENT must be current or stage or public! Not $ENVIRONMENT! \n" && exit 1; fi

if [ -z $BRANCHNAME ]; then printf "[ERROR_BRANCHNAME] Branchname must be passed \n" && exit 1; fi

if [ -z $mark ]; then printf "[ERROR_MARK] mark must be passed \n" && exit 1; fi

if [ "$mark" = "all" ] || [ "$mark" = "initiate-android" ]; then
        echo \[WARN_MARK\] branch name is \<b\>$BRANCHNAME\</b\>\<br\>ENVIRONMENT is \<b\>$ENVIRONMENT\</b\>\<br\>ID is \<b\>$ID\</b\>
elif ! [ "$mark"  = "all" ] || ! [ "$mark"  = "initiate-android" ]; then
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
TARGETS_REPO="targets"
URL_TARGETS_JSON="http://wpp.isd.dp.ua/irls-reader-artifacts"

### Create associative array
deploymentPackageId=($(echo $ID))
printf "Array deploymentPackageId contain nexts elements:\n"
printf '%s\n' "${deploymentPackageId[@]}"

declare -A combineArray
for ((x=0; x<${#deploymentPackageId[@]}; x++))
do
        a=$(echo "${deploymentPackageId[x]}" | cut -d"_" -f 2-)
        combineArray+=(["$a"]="${deploymentPackageId[x]}")
done

printf "Associative array combineArray contains next key-value elements:\n"
for k in "${!combineArray[@]}"
do
        printf '%s\n' "key: $k -- value: ${combineArray[$k]}"
done

###
### Functions
###

### Functions for body of script
function repack {
        # $1 - it's $CURRENT_ARTIFACTS_DIR or $STAGE_ARTIFACTS_DIR
        # $2 - it's $CURRENT_ARTIFACTS_DIR or $STAGE_ARTIFACTS_DIR or $PUBLIC_ARTIFACTS_DIR
        # checking the existence of a remote directory for the artifacts
	if [ $ENVIRONMENT == current ] || [ $ENVIRONMENT == stage ]; then
        	if [ ! -d $2 ]; then mkdir -p $2; fi
	elif [ $ENVIRONMENT == public ]; then
		$SSH_COMMAND "if [ ! -d $2 ]; then mkdir -p $2; fi"
	fi
        # creating temporary directory
        if [ ! -d $TEMPORARY_APK_REPACKING_DIR ]; then mkdir -p $TEMPORARY_APK_REPACKING_DIR; else rm -rf $TEMPORARY_APK_REPACKING_DIR/*; fi
        cd $TEMPORARY_APK_REPACKING_DIR
        # copying of apk-file from $1 environment directory to temporary directory
        cp $1/$APK_FILE_NAME .
        # checking the existence of a apk-file
        if [ ! -f $APK_FILE_NAME ]; then printf "[ERROR_FILE_EXIST] .APK-file NOT FOUND!!! \n" && exit 1; fi
        # unpacking apk-file
        unzip $APK_FILE_NAME
        # removing of apk-file
        rm -f $APK_FILE_NAME
        # adding or changing of "currentURL" option from build.info.json config file
        BUILD_INFO_JSON="www/dist/app/client.config.json"
        if [ $ENVIRONMENT == current ]; then
            if grep currentURL assets/$BUILD_INFO_JSON; then
                    sed -i "/currentURL/d" assets/$BUILD_INFO_JSON
            fi
            LINE_FEED='\n'; sed -i "1s@\(.*\)@{$LINE_FEED    \"currentURL\": \"$CURRENT_URL\",@" assets/$BUILD_INFO_JSON
        elif [ $ENVIRONMENT == stage ]; then
            sed -i "2s@\(.*\)@    \"currentURL\": \"$CURRENT_URL\",@" assets/$BUILD_INFO_JSON
        elif [ $ENVIRONMENT == public ]; then
            sed -i "2s@\(.*\)@    \"currentURL\": \"$CURRENT_URL\",@" assets/$BUILD_INFO_JSON
        else
            exit 1
        fi
        # create and sign of apk-file
        rm -rf META-INF
		zip -r -9 $APK_FILE_NAME *
		jarsigner -keystore ~/.android/debug.keystore -storepass android -keypass android $APK_FILE_NAME androiddebugkey
        # test archive (apk) file
        unzip -t -q $APK_FILE_NAME
        # copying of apk-file to $2 environment directory from temporary directory
        if [ $ENVIRONMENT == current ] || [ $ENVIRONMENT == stage ]; then
                cp $APK_FILE_NAME $2/
        elif [ $ENVIRONMENT == public ]; then
                scp $APK_FILE_NAME dvac@devzone.dp.ua:$2/
        fi

}

function ssh_and_start_node {
        $SSH_COMMAND "
                export PATH=$PATH:$NODE_PATH/bin
                # Start node
                cd $1
                PID=\$(ps aux | grep node.*server/$INDEX_FILE | grep -v grep | /usr/bin/awk '{print \$2}')
                if [ ! -z \$PID ];then
                        kill -9 \$PID
                        nohup node server/$INDEX_FILE > /dev/null 2>&1 &
                else
                        nohup node server/$INDEX_FILE > /dev/null 2>&1 &
                fi"
        }
function start_node {
                export PATH=$PATH:$NODE_PATH/bin
                # Start node
                cd $1
                PID=$(ps aux | grep node.*server/$INDEX_FILE | grep -v grep | /usr/bin/awk '{print $2}')
                if [ ! -z $PID ];then
                        kill -9 $PID
                        nohup node server/$INDEX_FILE > /dev/null 2>&1 &
                else
                        nohup node server/$INDEX_FILE > /dev/null 2>&1 &
                fi
        }

function create_configs {
        # $1 - it's $CURRENT_PKG_DIR or $STAGE_PKG_DIR
        sudo /home/jenkins/scripts/portgenerator-for-deploy.sh $BRANCH $i $ENVIRONMENT ${combineArray[$i]}
        if [ ! -d $CURRENT_PKG_DIR/server/config ]; then mkdir -p $1/server/config; fi
        }

###
### Body
###
for i in "${!combineArray[@]}"
do
        echo starting of main loop...
        ### Output value for a pair "key-value"
        printf '%s\n' "key: $i -- value: ${combineArray[$i]}"
        ### Determine of brand
	BRAND=$(curl -s $URL_TARGETS_JSON/$TARGETS_REPO.json | grep '"target_name": "'$i'"' | sed 's/^\(.*\)brand"//g' | awk -F '"|"' '{print $2}')
        ### Temporary local variables
        # terms for different environments
        if [ $ENVIRONMENT == current ] || [ $ENVIRONMENT == stage ]; then
                NODE_PATH="/opt/node"
                CURRENT_URL="https://wpps.isd.dp.ua/irls/$ENVIRONMENT/reader/$i/$BRANCH/"
        elif [ $ENVIRONMENT == public ]; then
                SSH_COMMAND="ssh dvac@devzone.dp.ua"
                NODE_PATH="/home/dvac/node"
                CURRENT_URL="https://irls.isd.dp.ua/$i/$BRANCH/"
        fi
        CURRENT_ARTIFACTS_DIR=$CURRENT_ART_PATH/${combineArray[$i]}/packages/artifacts
        CURRENT_PKG_DIR=$CURRENT_ART_PATH/${combineArray[$i]}/packages
        STAGE_ARTIFACTS_DIR=$STAGE_ART_PATH/${combineArray[$i]}/packages/artifacts
        STAGE_PKG_DIR=$STAGE_ART_PATH/${combineArray[$i]}/packages
        REMOTE_ART_PATH="/home/dvac/irls-reader-artifacts"
        PUBLIC_ARTIFACTS_DIR="$REMOTE_ART_PATH/${combineArray[$i]}/art"
        INDEX_FILE='index_'$i'_'$BRANCH'_'$ENVIRONMENT'.js'
        ### Determine of apk name
		APK_NAME=$(echo $BRANCH-"$BRAND"_Reader-$i)
		APK_FILE_NAME="$APK_NAME.apk"
        TEMPORARY_APK_REPACKING_DIR="$HOME/tmp_repacking_apk-$i"
        ### Checking contain platform
	if curl -s $URL_TARGETS_JSON/$TARGETS_REPO.json | grep '"target_name": "'$i'"' | grep "platforms.*android"; then
                ### Repacking of apk-file and creating local.json for node-server side, apache-proxying config and starting of node-server side
                if [ $ENVIRONMENT == current ]; then
                        repack $CURRENT_ARTIFACTS_DIR $CURRENT_ARTIFACTS_DIR
                        create_configs $CURRENT_PKG_DIR
                        start_node $CURRENT_PKG_DIR
                elif [ $ENVIRONMENT == stage ]; then
                        repack $CURRENT_ARTIFACTS_DIR $STAGE_ARTIFACTS_DIR
                        create_configs $STAGE_PKG_DIR
                        start_node $STAGE_PKG_DIR
                elif [ $ENVIRONMENT == public ]; then
                        repack $STAGE_ARTIFACTS_DIR $PUBLIC_ARTIFACTS_DIR
                        ssh dvac@devzone.dp.ua "
                                if [ ! -d  $REMOTE_ART_PATH/${combineArray[$i]} ]; then mkdir -p $REMOTE_ART_PATH/${combineArray[$i]}; fi
                                # Shorten path. Because otherwise - > Error of apache named AH00526 (ProxyPass worker name too long)
								if [ ! -d  $PUBLIC_ARTIFACTS_DIR ]; then mkdir -p $PUBLIC_ARTIFACTS_DIR; fi
                                /home/dvac/scripts/portgen-deploy-live.sh $BRANCH $i $ENVIRONMENT ${combineArray[$i]}"
                        ssh_and_start_node $REMOTE_ART_PATH/${combineArray[$i]}
                fi
                ### Updating environment.json file
                /home/jenkins/scripts/search_for_environment.sh ${combineArray[$i]} $ENVIRONMENT
        else
                echo "Shutdown of this job because platform \"android\" not found in config targetConfig.json"
                echo \[WARN_MARK\] just running on empty for $i
                exit 0
        fi
done
