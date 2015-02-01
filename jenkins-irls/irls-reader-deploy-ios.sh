# This script executes on the remote host named Yuriys-mac-mini.isd.dp.ua

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

if [ "$mark" = "all" ] || [ "$mark" = "initiate-ios" ]; then
	echo \[WARN_MARK\] branch name is \<b\>$BRANCHNAME\</b\>\<br\>ENVIRONMENT is \<b\>$ENVIRONMENT\</b\>\<br\>ID is \<b\>$ID\</b\>
elif ! [ "$mark"  = "all" ] || ! [ "$mark"  = "initiate-ios" ]; then
	echo \[WARN_MARK\] just running on empty
	exit 0
fi

###
### Constant local variables
###
BRANCH=$(echo $BRANCHNAME | sed -e 's@\/@-@g' -e 's@_@-@g')
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
	# clone targets-repo and running node with target option
	if [ ! -d $WORKSPACE/$1 ]; then
		git_clone
		git_checkout
	else
		git_checkout
	fi
	}

### Functions for body of script
function ssh_and_repack {
	# $1 - it's $CURRENT_ARTIFACTS_DIR or $STAGE_ARTIFACTS_DIR 
	# $2 - it's $CURRENT_ARTIFACTS_DIR or $STAGE_ARTIFACTS_DIR or $PUBLIC_ARTIFACTS_DIR
	# checking the existence of a remote directory for the artifacts
	$SSH_COMMAND "if [ ! -d $2 ]; then mkdir -p $2; fi"
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
        elif [ $ENVIRONMENT == public ]; then
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
        elif [ $ENVIRONMENT == public ]; then
		scp $IPA_FILE_NAME dvac@devzone.dp.ua:$2/
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

function ssh_and_create_configs {
	# $1 - it's $CURRENT_PKG_DIR or $STAGE_PKG_DIR
	$SSH_COMMAND "
		sudo /home/jenkins/scripts/portgenerator-for-deploy.sh $BRANCH $i $ENVIRONMENT ${combineArray[$i]}
		if [ ! -d $CURRENT_PKG_DIR/server/config ]; then mkdir -p $1/server/config; fi
		#cp ~/local.json $1/server/config/"
	}

###
### Body
###
for i in "${!combineArray[@]}"
do
	echo starting of main loop...
	### Output value for a pair "key-value"
        printf '%s\n' "key: $i -- value: ${combineArray[$i]}"
	### Clone or checkout of targets-repo
	REPONAME="$TARGETS_REPONAME"
	git_clone_or_checkout $REPONAME
	### Determine of brand          
	BRAND=$(grep brand $WORKSPACE/$TARGETS_REPONAME/$i/targetConfig.json | awk -F '"|"' '{print $4}')
	### Temporary local variables
	# terms for different environments
	if [ $ENVIRONMENT == current ] || [ $ENVIRONMENT == stage ]; then
		SSH_COMMAND="ssh jenkins@dev01.isd.dp.ua"
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
	IPA_NAME=$(echo $BRANCH-"$BRAND"_Reader-$i)
	IPA_FILE_NAME="$IPA_NAME.ipa"
	TEMPORARY_IPA_REPACKING_DIR="$HOME/tmp_repacking_ipa-$i"
	### Checking contain platform
	if grep "platforms.*ios" $WORKSPACE/$TARGETS_REPONAME/$i/targetConfig.json; then
		
		### Repacking of ipa-file and creating local.json for node-server side, apache-proxying config and starting of node-server side
		if [ $ENVIRONMENT == current ]; then 
			ssh_and_repack $CURRENT_ARTIFACTS_DIR $CURRENT_ARTIFACTS_DIR
			ssh_and_create_configs $CURRENT_PKG_DIR
			ssh_and_start_node $CURRENT_PKG_DIR
		elif [ $ENVIRONMENT == stage ]; then 
			ssh_and_repack $CURRENT_ARTIFACTS_DIR $STAGE_ARTIFACTS_DIR
			ssh_and_create_configs $STAGE_PKG_DIR
			ssh_and_start_node $STAGE_PKG_DIR
		elif [ $ENVIRONMENT == public ]; then
			ssh_and_repack $STAGE_ARTIFACTS_DIR $PUBLIC_ARTIFACTS_DIR
			ssh dvac@devzone.dp.ua "
				if [ ! -d  $REMOTE_ART_PATH/${combineArray[$i]} ]; then mkdir -p $REMOTE_ART_PATH/${combineArray[$i]}; fi
				# Shorten path. Because otherwise - > Error of apache named AH00526 (ProxyPass worker name too long)
				if [ ! -d  $PUBLIC_ARTIFACTS_DIR ]; then mkdir -p $PUBLIC_ARTIFACTS_DIR; fi
				/home/dvac/scripts/portgen-deploy-live.sh $BRANCH $i $ENVIRONMENT ${combineArray[$i]}
				cp ~/local.json $REMOTE_ART_PATH/${combineArray[$i]}/server/config"
			ssh_and_start_node $REMOTE_ART_PATH/${combineArray[$i]}
		fi
		### Updating environment.json file
		ssh jenkins@dev01.isd.dp.ua "/home/jenkins/scripts/search_for_environment.sh ${combineArray[$i]} $ENVIRONMENT"
	else
		echo "Shutdown of this job because platform \"ios\" not found in config targetConfig.json"
		echo \[WARN_MARK\] just running on empty for $i
		exit 0
	fi
done
