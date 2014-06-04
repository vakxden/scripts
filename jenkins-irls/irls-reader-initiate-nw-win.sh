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
###
### Body (working with all facets exclude only facet named "ocean")
###

for facet in ${FACETS[@]}
do
	if [ $(echo "$facet" | egrep "ocean$") ]; then
		printf "we can only work with the all facets exclude 'ocean' \n"
	else
		### Remove old version of project and zip-archives
		if [ ! -d zip ]; then mkdir zip; fi
		### Copy project to workspace
		# this line commented because this job was moved to host dev02.design.isd.dp.ua
		#cp -Rf $CURRENT_BUILD/$GIT_COMMIT/* .
		# this line there because this job working in host dev02.design.isd.dp.ua
		cp -Rf $CURRENT_BUILD/* .
		### Create associative array
		deploymentPackageId=($(echo $ID))
		ELEMENT_OF_FACETS=($facet)
		declare -A combineArray
		for ((x=0; x<${#deploymentPackageId[@]}; x++))
		do
			for ((y=0; y<${#ELEMENT_OF_FACETS[@]}; y++))
			do
				if [ -n "$(echo "${deploymentPackageId[x]}" | grep "${ELEMENT_OF_FACETS[y]}$")" ]; then
					combineArray+=(["${ELEMENT_OF_FACETS[y]}"]="${deploymentPackageId[x]}")
				fi
			done
		done
		### Create zip-archive with application version for Windows
		for i in "${!combineArray[@]}"
		do
			echo $i --- ${combineArray[$i]}
			cd $WORKSPACE/packager
			node index.js --target=win --config=/home/jenkins/build_config --from=$WORKSPACE/client --manifest=$WORKSPACE/client/package.json --prefix=$BRANCH- --suffix=-$i --epubs=$CURRENT_EPUBS/$i
			mv $WORKSPACE/packager/out/dest/*.zip $WORKSPACE/zip/
			# this lines commented because this job was moved to host dev02.design.isd.dp.ua
			#if [ ! -d $ARTIFACTS_DIR/${combineArray[$i]}/packages/artifacts ]; then
			#	mkdir -p $ARTIFACTS_DIR/${combineArray[$i]}/packages/artifacts
			#fi
			ssh jenkins@dev01.isd.dp.ua "
			if [ ! -d $ARTIFACTS_DIR/${combineArray[$i]}/packages/artifacts ]; then
				mkdir -p $ARTIFACTS_DIR/${combineArray[$i]}/packages/artifacts
			fi
			"
			# this line commented because this job was moved to host dev02.design.isd.dp.ua
			#cp $WORKSPACE/zip/*$i-win*.zip $ARTIFACTS_DIR/${combineArray[$i]}/packages/artifacts/
			# this line there because this job working in host dev02.design.isd.dp.ua
			scp $WORKSPACE/zip/*$i-win*.zip jenkins@dev01.isd.dp.ua:$ARTIFACTS_DIR/${combineArray[$i]}/packages/artifacts/
		done
	fi
done
