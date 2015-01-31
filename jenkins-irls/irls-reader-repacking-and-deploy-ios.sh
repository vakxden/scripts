# This script executes on the remote host named Yuriys-mac-mini.isd.dp.ua

###
### Checking variables that were passed to the current script
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
HOME=/Users/jenkins
CODE_SIGN_IDENTITY="iPhone Distribution: Yuriy Ponomarchuk (UC7ZS26U3J)"
MOBILEPROVISION=$HOME/mobileprovision_profile/jenkinsdistribution_profile_2015-02-04.mobileprovision
TARGETS_REPONAME="targets"


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
        printf '%s\n' "key: $k -- value: ${combineArray[$k]}"
done


###
### Functions
###

### Functions for git command
function git_clone {
        cd $WORKSPACE
        git clone git@wpp.isd.dp.ua:irls/$REPONAME.git
        }

function git_checkout {
        cd $WORKSPACE/$REPONAME
        git reset --hard
        git clean -fdx
        git fetch --all
        git checkout origin/master
        }

function git_clone_or_checkout {
	### Clone targets-repo and running node with target option
	if [ ! -d $WORKSPACE/$1 ]; then
		git_clone
		git_checkout
	else
		git_checkout
	fi
	}

### Functions for body of script
function ssh_and_repack {
	# checking the existence of a remote directory with the artifacts ($1 and $2)
	ssh jenkins@dev01.isd.dp.ua "if [ ! -d $1 ]; then mkdir -p $1; fi"
	if [ $ENVIRONMENT == current ] || [ $ENVIRONMENT == stage ]; then
		ssh jenkins@dev01.isd.dp.ua "if [ ! -d $2 ]; then mkdir -p $2; fi"
        elif [ $ENVIRONMENT == live ]; then
		ssh dvac@devzone.dp.ua "if [ ! -d $2 ]; then mkdir -p $2; fi"
	fi
	# terms for different environments
        if [ $ENVIRONMENT == current ] || [ $ENVIRONMENT == stage ]; then
                CURRENT_URL="https://wpps.isd.dp.ua/irls/$ENVIRONMENT/reader/$i/$BRANCH/"
        elif [ $ENVIRONMENT == live ]; then
                CURRENT_URL="https://irls.isd.dp.ua/$i/$BRANCH/"
        fi
	# creating temporary directory
	if [ ! -d $TEMPORARY_IPA_REPACKING_DIR ]; then mkdir -p $TEMPORARY_IPA_REPACKING_DIR; else rm -rf $TEMPORARY_IPA_REPACKING_DIR/*; fi
        cd $TEMPORARY_IPA_REPACKING_DIR
	# copying of ipa-file from $1 environment directory to temporary directory
	scp jenkins@dev01.isd.dp.ua:$1/$IPA_FILE_NAME .
	# checking the existence of a ipa-file
	if [ ! -f $IPA_FILE_NAME ]; then printf "[ERROR_FILE_EXIST] .IPA-file NOT FOUND!!! \n" && exit 1; fi
	# unpacking ipa-file
        unzip $IPA_FILE_NAME
	# removing of ipa-file
        rm -f $IPA_FILE_NAME
	# adding or changing of "currentURL" option from build.info.json config file
	BUILD_INFO_JSON="www/dist/app/build.info.json"
        if [ $ENVIRONMENT == current ]; then
		if grep currentURL Payload/$IPA_NAME.app/$BUILD_INFO_JSON; then
			sed -i '' "/currentURL/d" Payload/$IPA_NAME.app/$BUILD_INFO_JSON
		fi
		nl=$'\n'; sed -i '' "1s@\(.*\)@{\\$nl    \"currentURL\": \"$CURRENT_URL\",@" Payload/$IPA_NAME.app/$BUILD_INFO_JSON
        elif [ $ENVIRONMENT == stage ]; then
                sed -i '' "2s@\(.*\)@    \"currentURL\": \"$CURRENT_URL\",@" Payload/$IPA_NAME.app/$BUILD_INFO_JSON
        elif [ $ENVIRONMENT == live ]; then
                sed -i '' "2s@\(.*\)@    \"currentURL\": \"$CURRENT_URL\",@" Payload/$IPA_NAME.app/$BUILD_INFO_JSON
        else
                exit 1
        fi
	# create and sign of ipa-file
	security unlock-keychain -p jenk123ins $HOME/Library/Keychains/login.keychain
	/usr/bin/xcrun -sdk iphoneos8.1 PackageApplication -v $TEMPORARY_IPA_REPACKING_DIR/Payload/$IPA_NAME.app -o $TEMPORARY_IPA_REPACKING_DIR/$IPA_FILE_NAME --embed $MOBILEPROVISION --sign "$CODE_SIGN_IDENTITY"
	# test archive (ipa) file
	unzip -t -q $IPA_FILE_NAME
	# copying of ipa-file to $2 environment directory from temporary directory
        if [ $ENVIRONMENT == current ] || [ $ENVIRONMENT == stage ]; then
		scp $IPA_FILE_NAME jenkins@dev01.isd.dp.ua:$2/
        elif [ $ENVIRONMENT == live ]; then
		scp $IPA_FILE_NAME dvac@devzone.dp.ua:$2/
	fi
}

function ssh_and_start_node {
        if [ $ENVIRONMENT == current ] || [ $ENVIRONMENT == stage ]; then
		SSH_COMMAND="ssh jenkins@dev01.isd.dp.ua"
		NODE_PATH="/opt/node"
        elif [ $ENVIRONMENT == live ]; then
		SSH_COMMAND="ssh dvac@devzone.dp.ua"
		NODE_PATH="/home/dvac/node"
	fi
		
	$SSH_COMMAND "
		export PATH=$PATH:$NODE_PATH/bin
		# Start node
		cd $CURRENT_PKG_DIR
		PID=\$(ps aux | grep node.*server/$INDEX_FILE | grep -v grep | /usr/bin/awk '{print \$2}')
		if [ ! -z \$PID ];then
			kill -9 \$PID
			nohup node server/$INDEX_FILE > /dev/null 2>&1 &
		else
			nohup node server/$INDEX_FILE > /dev/null 2>&1 &
		fi"
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
		### Clone or checkout of targets-repo
		REPONAME="$TARGETS_REPONAME"
		git_clone_or_checkout $REPONAME
		### Determine of brand		
                BRAND=$(grep brand $WORKSPACE/$TARGETS_REPONAME/$i/targetConfig.json | awk -F '"|"' '{print $4}')
                ### Checking contain platform
                if grep "platforms.*ios" $WORKSPACE/$TARGETS_REPONAME/$i/targetConfig.json; then
                        IPA_NAME=$(echo $BRANCH-"$BRAND"_Reader-$i)
                        IPA_FILE_NAME="$IPA_NAME.ipa"
                        TEMPORARY_IPA_REPACKING_DIR="$HOME/tmp_repacking_ipa-$i"
                        # repacking of ipa-file
                        ssh_and_repack $CURRENT_ARTIFACTS_DIR $CURRENT_ARTIFACTS_DIR
                        ssh jenkins@dev01.isd.dp.ua "
        			sudo /home/jenkins/scripts/portgenerator-for-deploy.sh $BRANCH $i $dest ${combineArray[$i]}
				if [ ! -d $CURRENT_PKG_DIR/server/config ]; then mkdir -p $CURRENT_PKG_DIR/server/config; fi
                                cp ~/local.json $CURRENT_PKG_DIR/server/config/"
			# start node
			ssh_and_start_node
                        # update environment.json file
                        ssh jenkins@dev01.isd.dp.ua "/home/jenkins/scripts/search_for_environment.sh ${combineArray[$i]} $dest"
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
		### Clone or checkout of targets-repo
		REPONAME="$TARGETS_REPONAME"
		git_clone_or_checkout $REPONAME
		### Determine of brand		
                BRAND=$(grep brand $WORKSPACE/$TARGETS_REPONAME/$i/targetConfig.json | awk -F '"|"' '{print $4}')
                ### Checking contain platform
                if grep "platforms.*ios" $WORKSPACE/$TARGETS_REPONAME/$i/targetConfig.json; then
                        IPA_NAME=$(echo $BRANCH-"$BRAND"_Reader-$i)
                        IPA_FILE_NAME="$IPA_NAME.ipa"
                        TEMPORARY_IPA_REPACKING_DIR="$HOME/tmp_repacking_ipa-$i"
                        # repacking of ipa-file
                        ssh_and_repack $CURRENT_ARTIFACTS_DIR $STAGE_ARTIFACTS_DIR
                        ssh jenkins@dev01.isd.dp.ua "
        			sudo /home/jenkins/scripts/portgenerator-for-deploy.sh $BRANCH $i $dest ${combineArray[$i]}
				if [ ! -d $STAGE_PKG_DIR/server/config ]; then mkdir -p $STAGE_PKG_DIR/server/config; fi
                                cp ~/local.json $STAGE_PKG_DIR/server/config/"
			# start node
			ssh_and_start_node
                        # update environment.json file
                        ssh jenkins@dev01.isd.dp.ua "/home/jenkins/scripts/search_for_environment.sh ${combineArray[$i]} $dest"
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
                TEMPORARY_IPA_REPACKING_DIR="$HOME/tmp_repacking_ipa-$i"
                ENVIRONMENT="live"
		### Clone or checkout of targets-repo
		REPONAME="$TARGETS_REPONAME"
		git_clone_or_checkout $REPONAME
		### Determine of brand		
                BRAND=$(grep brand $WORKSPACE/$TARGETS_REPONAME/$i/targetConfig.json | awk -F '"|"' '{print $4}')
                ### Checking contain platform
                if grep "platforms.*ios" $WORKSPACE/$TARGETS_REPONAME/$i/targetConfig.json; then
                        IPA_NAME=$(echo $BRANCH-"$BRAND"_Reader-$i)
                        IPA_FILE_NAME="$IPA_NAME.ipa"
                        # repacking of ipa-file
                        ssh_and_repack $STAGE_ARTIFACTS_DIR $LIVE_ARTIFACTS_DIR
                        ssh dvac@devzone.dp.ua "
                                # values
                                if [ ! -d  $REMOTE_ART_PATH/${combineArray[$i]} ]; then mkdir -p $REMOTE_ART_PATH/${combineArray[$i]}; fi
                                # Shorten path. Because otherwise - > Error of apache named AH00526 (ProxyPass worker name too long)
                                if [ ! -d  $LIVE_ARTIFACTS_DIR ]; then mkdir -p $LIVE_ARTIFACTS_DIR; fi
                                /home/dvac/scripts/portgen-deploy-live.sh $BRANCH $i $dest ${combineArray[$i]}
                                cp ~/local.json $REMOTE_ART_PATH/${combineArray[$i]}/server/config"
			# start node
			ssh_and_start_node
                        # update environment.json file
                        ssh jenkins@dev01.isd.dp.ua "/home/jenkins/scripts/search_for_environment.sh ${combineArray[$i]} $dest"
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
