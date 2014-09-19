###
### Variables
###
export PATH=$PATH:/usr/local/bin
export HTTP_PROXY=http://10.98.192.120:3128
export HTTPS_PROXY=http://10.98.192.120:3128
CURRENT_BUILD=/Users/jenkins/irls-reader-current-build
BUILD_CONFIG=/Users/jenkins/build_config
CURRENT_EPUBS=/Users/jenkins/irls-reader-current-epubs
ARTIFACTS_DIR=/home/jenkins/irls-reader-artifacts # it's directory locates on the host dev01
echo SHELL=$BASH
echo SHELL_VERSION=$BASH_VERSION
BRANCH=$(echo $BRANCHNAME | sed 's/\//-/g' | sed 's/_/-/g')
CURRENT_BUILD=/Users/jenkins/irls-reader-current-build
CONFIGURATION_BUILD_DIR=$WORKSPACE/build
CODE_SIGN_IDENTITY="iPhone Distribution: Yuriy Ponomarchuk (UC7ZS26U3J)"
MOBILEPROVISION=$HOME/mobileprovision_profile/jenkinsdistribution_profile_2015-02-04.mobileprovision
FACETS=($(echo $FACET))
###
### Body (working with all facets exclude "ocean")
###

### Create associative array
deploymentPackageId=($(echo $ID))
declare -A combineArray
for ((x=0; x<${#deploymentPackageId[@]}; x++))
do
	for ((y=0; y<${#FACETS[@]}; y++))
	do
		if [ -n "$(echo "${deploymentPackageId[x]}" | grep "${FACETS[y]}$")" ]; then
			combineArray+=(["${FACETS[y]}"]="${deploymentPackageId[x]}")
		fi
	done
done
### Create ipa-file with application version for iOS
function main_loop {
	notmainloop ()
	{
	if [ $(echo "$i" | grep "ocean$") ]; then
		printf "we can only work with the all facets exclude 'ocean' \n not $facet ! \n"
	else
		cd $WORKSPACE/packager
		time node index.js --platform=ios --config=$WORKSPACE/targets --from=$WORKSPACE/client --prefix=$BRANCH- --epubs=$CURRENT_EPUBS
		#unlock keychain
		security unlock-keychain -p jenk123ins /Users/jenkins/Library/Keychains/login.keychain
		#build with xcodebuild
		time /usr/bin/xcodebuild -target "$BRANCH-FFA_Reader-$i" -configuration Release clean build CONFIGURATION_BUILD_DIR=$CONFIGURATION_BUILD_DIR CODE_SIGN_IDENTITY="$CODE_SIGN_IDENTITY" -project $WORKSPACE/packager/out/dest/platforms/ios/$BRANCH-FFA_Reader-$i.xcodeproj/  -arch armv7 > /dev/null
		#create ipa-file
		time /usr/bin/xcrun -sdk iphoneos PackageApplication -v "$WORKSPACE/build/$BRANCH-FFA_Reader-$i.app" -o $WORKSPACE/$BRANCH-FFA_Reader-$i.ipa --embed $MOBILEPROVISION --sign "$CODE_SIGN_IDENTITY"
		rm -f $WORKSPACE/*$i*debug.ipa
		until time scp -v $WORKSPACE/$BRANCH-FFA_Reader-$i.ipa  jenkins@dev01.isd.dp.ua:$ARTIFACTS_DIR/${combineArray[$i]}/packages/artifacts/ && rm -f $WORKSPACE/$BRANCH-FFA_Reader-$i.ipa; do :; done
		rm -rf $CONFIGURATION_BUILD_DIR/*
	fi
	}

	for i in "${!combineArray[@]}"
	do
		rm -rf $WORKSPACE/*
		#if [ "$i" = "ocean" ]; then BRAND="$i"_"Ocean"; else BRAND="$i"_"FFA"; fi
		if [ "$i" = "epubtest" ];then
                        BRAND=$(echo "$i"_irls)
                elif [ "$i" = "ocean" ];then
                        BRAND=$(echo "$i"_irls)
                elif [ "$i" = "audio" ];then
                        BRAND=$(echo "$i"_irls)
                elif [ "$i" = "audiobywords" ];then
                        BRAND=$(echo "$i"_irls)
                elif [ "$i" = "gutenberg" ];then
                        BRAND=$(echo "$i"_FFA)
                elif [ "$i" = "refbahai" ];then
                        BRAND=$(echo "$i"_Ocean)
                else
                        BRAND=$(echo "$i"_FFA)
                fi
		GIT_COMMIT_TARGET="$GIT_COMMIT"-"$BRAND"
		cp -Rf $CURRENT_BUILD/$GIT_COMMIT_TARGET/* $WORKSPACE/

		echo $i --- ${combineArray[$i]}
		### Checking contain platform
		#if [ "$BRANCHNAME" = "feature/platforms-config" ]; then
			if grep "platforms.*ios" $WORKSPACE/targets/$BRAND/targetConfig.json; then
				notmainloop
			else
				echo "Shutdown of this job because platform \"ios\" not found in config targetConfig.json"
				exit 0
			fi
		#else
		#	notmainloop
		#fi
	done
}

main_loop
