###
### path to node (because this job working in host dev02.design.isd.dp.ua)
###
export NODE_HOME=/opt/node
export PATH=$PATH:$NODE_HOME/bin/
###
### Variables
###
ARTIFACTS_DIR=/home/jenkins/irls-reader-artifacts
CURRENT_EPUBS=$HOME/irls-reader-current-epubs
BRANCH=$(echo $BRANCHNAME | sed 's/\//-/g' | sed 's/_/-/g')
#FACETS=(puddle bahaiebooks lake audio mediaoverlay)
FACETS=($(echo $FACET))
###
### Body (working with all facets exclude only facet named "ocean")
###
if [ "$FACETS" = "ocean" ]; then
	printf "facet named 'ocean' will not be processed \n"
else
	### Remove old version of project and zip-archives
	rm -rf client packager server zip/*.zip
	### Copy project to workspace
	if [ ! -d zip ]; then mkdir zip; fi
	# this line commented because this job was moved to host dev02.design.isd.dp.ua
	#cp -Rf $CURRENT_BUILD/$GIT_COMMIT/* .
	# this line there because this job working in host dev02.design.isd.dp.ua
	cp -Rf $CURRENT_BUILD/* .
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
	### Create zip-archive with application version for Linux 32-bit
	for i in "${!combineArray[@]}"
	do
		echo $i --- ${combineArray[$i]}
		cd $WORKSPACE/packager
		node index.js --target=linux32 --config=/home/jenkins/build_config --from=$WORKSPACE/client --manifest=$WORKSPACE/client/package.json --prefix=$BRANCH- --suffix=-$i --epubs=$CURRENT_EPUBS/$i
		mv $WORKSPACE/packager/out/dest/*.zip $WORKSPACE/zip/
		# this lines commented because this job was moved to host dev02.design.isd.dp.ua
		#if [ ! -d $ARTIFACTS_DIR/${combineArray[$i]}/packages/artifacts ]; then
		#	mkdir -p $ARTIFACTS_DIR/${combineArray[$i]}/packages/artifacts
		#fi
		# this lines there because this job working in host dev02.design.isd.dp.ua
		ssh jenkins@dev01.isd.dp.ua "
		if [ ! -d $ARTIFACTS_DIR/${combineArray[$i]}/packages/artifacts ]; then
			mkdir -p $ARTIFACTS_DIR/${combineArray[$i]}/packages/artifacts
		fi
		"
		# this line commented because this job was moved to host dev02.design.isd.dp.ua
		#cp $WORKSPACE/zip/*$i-linux32*.zip $ARTIFACTS_DIR/${combineArray[$i]}/packages/artifacts/
		# this line there because this job working in host dev02.design.isd.dp.ua
		scp $WORKSPACE/zip/*$i-linux32*.zip jenkins@dev01.isd.dp.ua:$ARTIFACTS_DIR/${combineArray[$i]}/packages/artifacts/
	done
	### Create zip-archive with application version for Linux 64-bit
	for i in "${!combineArray[@]}"
	do
		echo $i --- ${combineArray[$i]}
		cd $WORKSPACE/packager
		node index.js --target=linux64 --config=/home/jenkins/build_config --from=$WORKSPACE/client --manifest=$WORKSPACE/client/package.json --prefix=$BRANCH- --suffix=-$i --epubs=$CURRENT_EPUBS/$i
		mv $WORKSPACE/packager/out/dest/*.zip $WORKSPACE/zip/
		# this lines commented because this job was moved to host dev02.design.isd.dp.ua
		#if [ ! -d $ARTIFACTS_DIR/${combineArray[$i]}/packages/artifacts ]; then
		#	mkdir -p $ARTIFACTS_DIR/${combineArray[$i]}/packages/artifacts
		#fi
		# this lines there because this job working in host dev02.design.isd.dp.ua
		ssh jenkins@dev01.isd.dp.ua "
		if [ ! -d $ARTIFACTS_DIR/${combineArray[$i]}/packages/artifacts ]; then
			mkdir -p $ARTIFACTS_DIR/${combineArray[$i]}/packages/artifacts
		fi
		"
		# this line commented because this job was moved to host dev02.design.isd.dp.ua
		#cp $WORKSPACE/zip/*$i-linux64*.zip $ARTIFACTS_DIR/${combineArray[$i]}/packages/artifacts/
		# this line there because this job working in host dev02.design.isd.dp.ua
		scp $WORKSPACE/zip/*$i-linux64*.zip jenkins@dev01.isd.dp.ua:$ARTIFACTS_DIR/${combineArray[$i]}/packages/artifacts/
	done
fi
