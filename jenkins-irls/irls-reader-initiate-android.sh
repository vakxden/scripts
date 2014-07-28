###
### Variables
###

export NO_PROXY="127.0.0.1, 10.98.244.26, localhost, *.loc"
export FTP_PROXY="http://10.98.192.120:3128"
export HTTPS_PROXY="http://10.98.192.120:3128"
export https_proxy="http://10.98.192.120:3128"
export HTTP_PROXY="http://10.98.192.120:3128"
export http_proxy="http://10.98.192.120:3128"

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


###
### Body (working with all facets exclude "ocean")
###

### Remove old version of project
rm -rf $WORKSPACE/*
### Copy project to workspace
cp -Rf $CURRENT_BUILD/$GIT_COMMIT/* .
### Main loop
function main_loop {
	for i in "${!combineArray[@]}"
	do
		echo $i --- ${combineArray[$i]}
		if [ $(echo "$i" | egrep "ocean$") ]; then
			getAbort()
			{
	                	printf "we do not create the apk-file for facet named 'ocean'\n"
			}
			getAbort
			trap 'getAbort; exit' SIGTERM
	        else
			# Create apk-file
			cd $WORKSPACE/packager
			if [ "$BRANCHNAME" = "feature/target" ]; then
				time node index.js --platform=android --config=$WORKSPACE/targets --from=$WORKSPACE/client --manifest=$WORKSPACE/client/package.json --prefix=$BRANCH- --epubs=$CURRENT_EPUBS
			else
				time node index.js --target=android --config=/home/jenkins/build_config --from=$WORKSPACE/client --manifest=$WORKSPACE/client/package.json --prefix=$BRANCH- --suffix=-$i --epubs=$CURRENT_EPUBS/$i
			fi
			# Remove unaligned apk-file
			rm -f out/dest/platforms/android/bin/*$i*unaligned.apk
			# Move apk-file to directory for archiving artifacts
			mv $WORKSPACE/packager/out/dest/platforms/android/bin/*$i*.apk $WORKSPACE/$BRANCH-FFA_Reader-$i.apk
			# this lines commented because this job was moved to host dev02.design.isd.dp.ua
			#if [ ! -d $ARTIFACTS_DIR/${combineArray[$i]}/packages/artifacts ]; then
			#	mkdir -p $ARTIFACTS_DIR/${combineArray[$i]}/packages/artifacts
			#fi
			#cp $WORKSPACE/$BRANCH-FFA_Reader-$i.apk $ARTIFACTS_DIR/${combineArray[$i]}/packages/artifacts/
			ssh jenkins@dev01.isd.dp.ua "
			if [ ! -d $ARTIFACTS_DIR/${combineArray[$i]}/packages/artifacts ]; then
				mkdir -p $ARTIFACTS_DIR/${combineArray[$i]}/packages/artifacts
			fi
			"
			time scp $WORKSPACE/$BRANCH-FFA_Reader-$i.apk  jenkins@dev01.isd.dp.ua:$ARTIFACTS_DIR/${combineArray[$i]}/packages/artifacts/ && rm -f $WORKSPACE/$BRANCH-FFA_Reader-$i.apk
	        fi
	done
}

main_loop
