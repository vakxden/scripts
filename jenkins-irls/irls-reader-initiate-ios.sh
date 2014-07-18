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
MOBILEPROVISION=$HOME/mobileprovision_profile/jenkinsdistribution.mobileprovision
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
# Copy code of project from the current code directory to workspace of job
rm -rf $WORKSPACE/*
cp -Rf $CURRENT_BUILD/$GIT_COMMIT/* .
### Clean old ipa-file from workspace of job
rm -rf $WORKSPACE/*.ipa
### Create ipa-file with application version for iOS
for i in "${!combineArray[@]}"
do
	echo $i --- ${combineArray[$i]}
	if [ $(echo "$i" | grep "ocean$") ]; then
		printf "we can only work with the all facets exclude 'ocean' \n not $facet ! \n"
	else
		cd $WORKSPACE/packager
		time node index.js --target=ios --config=$BUILD_CONFIG --from=$WORKSPACE/client --prefix=$BRANCH- --suffix=-$i --epubs=$CURRENT_EPUBS/$i/
		#unlock keychain
		security unlock-keychain -p jenk123ins /Users/jenkins/Library/Keychains/login.keychain
		#build with xcodebuild
		time /usr/bin/xcodebuild -target "$BRANCH-FFA_Reader-$i" -configuration Release clean build CONFIGURATION_BUILD_DIR=$CONFIGURATION_BUILD_DIR CODE_SIGN_IDENTITY="$CODE_SIGN_IDENTITY" -project $WORKSPACE/packager/out/dest/platforms/ios/$BRANCH-FFA_Reader-$i.xcodeproj/ > /dev/null
		#create ipa-file
		time /usr/bin/xcrun -sdk iphoneos PackageApplication -v "$WORKSPACE/build/$BRANCH-FFA_Reader-$i.app" -o $WORKSPACE/$BRANCH-FFA_Reader-$i.ipa --embed $MOBILEPROVISION --sign "$CODE_SIGN_IDENTITY"
		time scp $WORKSPACE/$BRANCH-FFA_Reader-$i.ipa  jenkins@dev01.isd.dp.ua:$ARTIFACTS_DIR/${combineArray[$i]}/packages/artifacts/ && rm -f $WORKSPACE/$BRANCH-FFA_Reader-$i.ipa
	fi
done
rm -rf $CONFIGURATION_BUILD_DIR/*
