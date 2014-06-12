###
### Variables
###
BRANCH=$(echo $BRANCHNAME | sed 's/\//-/g' | sed 's/_/-/g')
ARTIFACTS_DIR=/home/jenkins/irls-reader-artifacts
CURRENT_EPUBS=$HOME/irls-reader-current-epubs
export NODE_HOME=/opt/node
export ANDROID_HOME=/opt/android-sdk-linux
export PATH=$PATH:$NODE_HOME/bin:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools:$JAVA_HOME/bin
FACETS=($(echo $FACET))

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

### Remove old version of project and zip-archives
rm -rf client packager server apk/*.apk

### Copy project to workspace
if [ ! -d apk ]; then mkdir apk; fi
cp -Rf $CURRENT_BUILD/$GIT_COMMIT/* .

###
### Body (working only with facets named "puddle", "mediaoverlay", "audio", "audiobywords")
###
for i in "${!combineArray[@]}"
do
	echo $i --- ${combineArray[$i]}
	if [ $(echo "$i" | egrep "puddle$|mediaoverlay$|audio$|audiobywords$") ]; then
		cd $WORKSPACE/packager
		node index.js --target=android --config=/home/jenkins/build_config --from=$WORKSPACE/client --manifest=$WORKSPACE/client/package.json --prefix=$BRANCH- --suffix=-$i --epubs=$CURRENT_EPUBS/$i
		# Remove unaligned apk-file
		rm -f out/dest/platforms/android/bin/*$i*unaligned.apk
		# Move apk-file to directory for archiving artifacts
		mv $WORKSPACE/packager/out/dest/platforms/android/bin/*$i*.apk $WORKSPACE/apk/$BRANCH-FFA_Reader-$i.apk
		if [ ! -d $ARTIFACTS_DIR/${combineArray[$i]}/packages/artifacts ]; then
			mkdir -p $ARTIFACTS_DIR/${combineArray[$i]}/packages/artifacts
		fi
		cp $WORKSPACE/apk/$BRANCH-FFA_Reader-$i.apk $ARTIFACTS_DIR/${combineArray[$i]}/packages/artifacts/
        else
                printf "we can only work with the two facets named 'puddle','mediaoverlay', 'audio', audiobywords \n"
        fi
done
