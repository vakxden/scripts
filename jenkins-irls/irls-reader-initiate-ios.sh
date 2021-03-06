###
### Variables
###
export PATH=$PATH:/usr/local/bin
export HTTP_PROXY=http://10.98.192.120:3128
export HTTPS_PROXY=http://10.98.192.120:3128
CURRENT_BUILD=/Users/jenkins/irls-reader-current-build
if [ "$BRANCHNAME" != "master" ]; then
        CURRENT_EPUBS=/Users/jenkins/irls-reader-current-epubs/develop
else
        CURRENT_EPUBS=/Users/jenkins/irls-reader-current-epubs/$BRANCHNAME
fi

ARTIFACTS_DIR=/home/jenkins/irls-reader-artifacts # it's directory locates on the host dev01
echo SHELL=$BASH
echo SHELL_VERSION=$BASH_VERSION
BRANCH=$(echo $BRANCHNAME | sed 's/\//-/g' | sed 's/_/-/g')
CONFIGURATION_BUILD_DIR=$WORKSPACE/build
#CODE_SIGN_IDENTITY="iPhone Distribution: Yuriy Ponomarchuk (UC7ZS26U3J)"
CODE_SIGN_IDENTITY="iPhone Distribution: Yuriy Ponomarchuk (UC7ZS26U3J)"
MOBILEPROVISION=$HOME/mobileprovision_profile/ios_distribution_2015_02_03_profile.mobileprovision
TARGET=($(echo $TARGET))
SDKROOT="/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS8.1.sdk"

###
### Body
###

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

### Create ipa-file with application version for iOS
function main_loop {
        notmainloop ()
        {
                BRAND=$(grep brand $WORKSPACE/targets/$i/targetConfig.json | awk -F '"|"' '{print $4}')
                IPA_NAME=$BRANCH-$BRAND\_Reader-$i
                if [ ! -d $WORKSPACE/build/build ]; then mkdir -p $WORKSPACE/build/build; fi
                if [ -d ~/build_re/$BRANCHNAME ]; then
                        cp -Rf ~/build_re/$BRANCHNAME/phonegap-plugins $WORKSPACE/build/build
                else
                        cp -Rf ~/build_re/develop/phonegap-plugins $WORKSPACE/build/build
                fi
                cd $WORKSPACE/build
                #if [ $BRANCHNAME == "master" ];
                #then
                #        time node index.js --platform=ios --config=$WORKSPACE/targets --from=$WORKSPACE/client --prefix=$BRANCH- --epubs=$CURRENT_EPUBS
		if [ $BRANCHNAME == "master" ] || [ $BRANCHNAME == "audio" ];
                then
                        time node index.js --platform=ios --config=$WORKSPACE/targets --from=$WORKSPACE/client --prefix=$BRANCH- --epubs=$CURRENT_EPUBS --buildnumber=$BUILD_NUMBER --builddate="$BUILD_DATE"
                else
                        time node index.js --platform=ios --workspace=$WORKSPACE --prefix=$BRANCH- --epubs=$CURRENT_EPUBS --buildnumber=$BUILD_NUMBER --builddate="$BUILD_DATE"
                fi
                #unlock keychain
                security unlock-keychain -p jenk123ins /Users/jenkins/Library/Keychains/login.keychain
                #build with xcodebuild
                time /usr/bin/xcodebuild -sdk iphoneos8.1 -target $IPA_NAME -configuration Release clean build CONFIGURATION_BUILD_DIR=$CONFIGURATION_BUILD_DIR CODE_SIGN_IDENTITY="$CODE_SIGN_IDENTITY" -project $WORKSPACE/build/out/dest/platforms/ios/$IPA_NAME.xcodeproj/ -arch armv7 CODE_SIGN_RESOURCE_RULES_PATH="$SDKROOT/ResourceRules.plist" > /dev/null
                #create ipa-file
                time /usr/bin/xcrun -sdk iphoneos8.1 PackageApplication -v "$WORKSPACE/build/$IPA_NAME.app" -o $WORKSPACE/$IPA_NAME.ipa --embed $MOBILEPROVISION --sign "$CODE_SIGN_IDENTITY"
                rm -f $WORKSPACE/$IPA_NAME*debug.ipa
                if [ -f $WORKSPACE/$IPA_NAME.ipa ]; then
                        ssh jenkins@dev01.isd.dp.ua "if [ ! -d $ARTIFACTS_DIR/${combineArray[$i]}/packages/artifacts ]; then mkdir -p $ARTIFACTS_DIR/${combineArray[$i]}/packages/artifacts; fi"
                        time scp $WORKSPACE/$IPA_NAME.ipa jenkins@dev01.isd.dp.ua:$ARTIFACTS_DIR/${combineArray[$i]}/packages/artifacts/
                        rm -f $WORKSPACE/$IPA_NAME.ipa
                        printf "File $WORKSPACE/$IPA_NAME.ipa moved to host dev01.isd.dp.ua \n"
                else
                        printf "[ERROR_FILE_EXIST] File $WORKSPACE/$IPA_NAME.ipa not found!!! \n"
                fi
                rm -f $WORKSPACE/$IPA_NAME.ipa
                rm -rf $CONFIGURATION_BUILD_DIR/*
        }

        for i in "${!combineArray[@]}"
        do
                rm -rf $WORKSPACE/*
                GIT_COMMIT_TARGET=$(echo "$GIT_COMMIT"-"$i")
                if [ ! -d $CURRENT_BUILD/$GIT_COMMIT_TARGET ]; then
                        echo "[ERROR_INITIATE] Directory not found! Maybe for this target ($i) disabled option platform:ios."
                        exit 1
                else
                        cp -Rf $CURRENT_BUILD/$GIT_COMMIT_TARGET/* $WORKSPACE/
                        echo $i --- ${combineArray[$i]}
                        notmainloop
                fi
        done
}

main_loop
