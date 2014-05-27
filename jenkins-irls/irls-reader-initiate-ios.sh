###
### Variables
###
BRANCH=$(echo $BRANCHNAME | sed 's/\//-/g' | sed 's/_/-/g')
CURRENT_BUILD=/Users/jenkins/irls-reader-current-build
CONFIGURATION_BUILD_DIR=$WORKSPACE/build
CODE_SIGN_IDENTITY="iPhone Distribution: Yuriy Ponomarchuk (UC7ZS26U3J)"
MOBILEPROVISION=$HOME/mobileprovision_profile/jenkinsdistribution.mobileprovision
#FACETS=(puddle bahaiebooks audio mediaoverlay)
FACETS=($(echo $FACET))
###
### Body (working only with facets named "puddle","bahaiebooks","audio" and "mediaoverlay")
###
if [ "$FACETS" = "puddle" ] || [ "$FACETS" = "bahaiebooks" ] || [ "$FACETS" = "audio" ] || [ "$FACETS" = "audiobywords" ] ||[ "$FACETS" = "mediaoverlay" ]; then
	# Copy code of project from the current code directory to workspace of job
	rm -rf $WORKSPACE/packager/* $WORKSPACE/packager $WORKSPACE/client/ 
	cp -Rf $CURRENT_BUILD/packager $CURRENT_BUILD/client $WORKSPACE
	### Clean old ipa-file from workspace of job
	rm -rf $WORKSPACE/*.ipa
	### Create associative array
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
	### Create ipa-file with application version for iOS
	for i in "${!combineArray[@]}"
	do
		echo $i --- ${combineArray[$i]}
		#DATE=$(date +%d-%b-%y_%H-%M-%S)
		cd $WORKSPACE/packager
		time node index.js --target=ios --config=$BUILD_CONFIG --from=$WORKSPACE/client --prefix=$BRANCH- --suffix=-$i --epubs=/Users/jenkins/irls-reader-current-epubs/$i/
		#unlock keychain
		security unlock-keychain -p jenk123ins /Users/jenkins/Library/Keychains/login.keychain
		#build with xcodebuild
		time /usr/bin/xcodebuild -target "$BRANCH-FFA_Reader-$i" -configuration Release clean build CONFIGURATION_BUILD_DIR=$CONFIGURATION_BUILD_DIR CODE_SIGN_IDENTITY="$CODE_SIGN_IDENTITY" -project $WORKSPACE/packager/out/dest/platforms/ios/$BRANCH-FFA_Reader-$i.xcodeproj/
		#create ipa-file
		time /usr/bin/xcrun -sdk iphoneos PackageApplication -v "$WORKSPACE/build/$BRANCH-FFA_Reader-$i.app" -o $WORKSPACE/build/ipa_file/$BRANCH-FFA_Reader-$i.ipa --embed $MOBILEPROVISION --sign "$CODE_SIGN_IDENTITY"
		
		if [ ! -d $CURRENT_BUILD/${combineArray[$i]} ]; then
			mkdir -p $CURRENT_BUILD/${combineArray[$i]}
		else
			rm -rf $CURRENT_BUILD/${combineArray[$i]}/*
		fi
		mv $WORKSPACE/build/ipa_file/*.ipa $CURRENT_BUILD/${combineArray[$i]}/
		# for archiving artifacts
		cp -Rf $CURRENT_BUILD/${combineArray[$i]}/$BRANCH-FFA_Reader-$i.ipa $WORKSPACE
		rm -rf $CURRENT_BUILD/${combineArray[$i]}
	done
else
	printf "not make sense to create ipa-file with the big facet \n"
fi
