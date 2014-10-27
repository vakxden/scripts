###
### Variables
###
export PATH=$PATH:/usr/local/bin
export HTTP_PROXY=http://10.98.192.120:3128
export HTTPS_PROXY=http://10.98.192.120:3128
CURRENT_BUILD=/Users/jenkins/irls-reader-current-build
CURRENT_EPUBS=/Users/jenkins/irls-reader-current-epubs
ARTIFACTS_DIR=/home/jenkins/irls-reader-artifacts # it's directory locates on the host dev01
echo SHELL=$BASH
echo SHELL_VERSION=$BASH_VERSION
BRANCH=$(echo $BRANCHNAME | sed 's/\//-/g' | sed 's/_/-/g')
CONFIGURATION_BUILD_DIR=$WORKSPACE/build
CODE_SIGN_IDENTITY="iPhone Distribution: Yuriy Ponomarchuk (UC7ZS26U3J)"
MOBILEPROVISION=$HOME/mobileprovision_profile/jenkinsdistribution_profile_2015-02-04.mobileprovision
TARGET=($(echo $TARGET))
###
### Body (working with all facets exclude "ocean")
###

### Create associative array
deploymentPackageId=($(echo $ID))
declare -A combineArray
for ((x=0; x<${#deploymentPackageId[@]}; x++))
do
	a=$(echo "${deploymentPackageId[i]}"| cut -d"_" -f 2-)
	combineArray+=(["$a"]="${deploymentPackageId[i]}")
        #for ((y=0; y<${#TARGET[@]}; y++))
        #do
        #        if [ -n "$(echo "${deploymentPackageId[x]}" | grep "${TARGET[y]}$")" ]; then
        #                combineArray+=(["${TARGET[y]}"]="${deploymentPackageId[x]}")
        #        fi
        #done
done
### Create ipa-file with application version for iOS
function main_loop {
        notmainloop ()
        {
		BRAND=$(grep brand $WORKSPACE/targets/$i/targetConfig.json | awk -F '"|"' '{print $4}')
		IPA_NAME=$BRANCH-$BRAND\_Reader-$i
                cd $WORKSPACE/packager
                time node index.js --platform=ios --config=$WORKSPACE/targets --from=$WORKSPACE/client --prefix=$BRANCH- --epubs=$CURRENT_EPUBS
                #unlock keychain
                security unlock-keychain -p jenk123ins /Users/jenkins/Library/Keychains/login.keychain
                #build with xcodebuild
                time /usr/bin/xcodebuild -target $IPA_NAME -configuration Release clean build CONFIGURATION_BUILD_DIR=$CONFIGURATION_BUILD_DIR CODE_SIGN_IDENTITY="$CODE_SIGN_IDENTITY" -project $WORKSPACE/packager/out/dest/platforms/ios/$IPA_NAME.xcodeproj/  -arch armv7 > /dev/null
                #create ipa-file
                time /usr/bin/xcrun -sdk iphoneos PackageApplication -v "$WORKSPACE/build/$IPA_NAME.app" -o $WORKSPACE/$IPA_NAME.ipa --embed $MOBILEPROVISION --sign "$CODE_SIGN_IDENTITY"
                rm -f $WORKSPACE/$IPA_NAME*debug.ipa
                until time scp $WORKSPACE/$IPA_NAME.ipa  jenkins@dev01.isd.dp.ua:$ARTIFACTS_DIR/${combineArray[$i]}/packages/artifacts/ && rm -f $WORKSPACE/$IPA_NAME.ipa; do :; done
		rm -f $WORKSPACE/$IPA_NAME.ipa
                rm -rf $CONFIGURATION_BUILD_DIR/*
        }

	for i in "${!combineArray[@]}"
	do
                rm -rf $WORKSPACE/*
                GIT_COMMIT_TARGET=$(echo "$GIT_COMMIT"-"$i")
                cp -Rf $CURRENT_BUILD/$GIT_COMMIT_TARGET/* $WORKSPACE/

                echo $i --- ${combineArray[$i]}
                ### Checking contain platform
		if grep "platforms.*ios" $WORKSPACE/targets/$i/targetConfig.json; then
			notmainloop
		else
			echo "Shutdown of this job because platform \"ios\" not found in config targetConfig.json"
			exit 0
		fi
	done
}

main_loop
