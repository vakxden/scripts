###
### This script takes the following parameters: 
###  BRANCHNAME 
###  GIT_TSOMMIT 
###  CURRENT_BUILD 
###  ID 
###  FACET
###

###
### path to node (because this job working in host dev02.design.isd.dp.ua)
###
export NODE_HOME=/opt/node
export PATH=$PATH:$NODE_HOME/bin/
###
### Variables
###
BRANCH=$(echo $BRANCHNAME | sed 's/\//-/g' | sed 's/_/-/g')
ARTIFACTS_DIR=/home/jenkins/irls-reader-artifacts
CURRENT_EPUBS=$HOME/irls-reader-current-epubs
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
### Body (working with all facets exclude only facet named "ocean")
###
# Main loop
function main_loop {
	notmainloop ()
	{
	if [ $(echo "$i" | egrep "ocean$") ]; then
		getAbort()
		{
                	printf "we do not create the zip-file for facet named 'ocean'\n"
		}
		getAbort
		trap 'getAbort; exit' SIGTERM
	else
		### Copy project to workspace
		if [ ! -d $WORKSPACE/zip ]; then mkdir $WORKSPACE/zip; fi
		### Create zip-archive with application version for MacOS
		cd $WORKSPACE/packager
		time node index.js --platform=macos --config=$WORKSPACE/targets --from=$WORKSPACE/client --manifest=$WORKSPACE/client/package.json --prefix=$BRANCH- --epubs=$CURRENT_EPUBS
		mv $WORKSPACE/packager/out/dest/*.zip $WORKSPACE/zip/
		ssh jenkins@dev01.isd.dp.ua "
		if [ ! -d $ARTIFACTS_DIR/${combineArray[$i]}/packages/artifacts ]; then
			mkdir -p $ARTIFACTS_DIR/${combineArray[$i]}/packages/artifacts
		fi
		"
		time scp $WORKSPACE/zip/*$i-macos*.zip jenkins@dev01.isd.dp.ua:$ARTIFACTS_DIR/${combineArray[$i]}/packages/artifacts/ && rm -f $WORKSPACE/zip/*$i-macos*.zip
		rm -rf $WORKSPACE/zip
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
			if grep "platforms.*macos" $WORKSPACE/targets/$BRAND/targetConfig.json; then
				notmainloop
			else
				echo "Shutdown of this job because platform \"macos\" not found in config targetConfig.json"
				exit 0
			fi
		#else
		#	notmainloop
		#fi
	done
}

main_loop
