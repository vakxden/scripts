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
### Copy project to workspace
###
rm -rf $WORKSPACE/*
cp -Rf $CURRENT_BUILD/$GIT_COMMIT/* .

###
### Body (working with all facets exclude only facet named "ocean")
###
for i in "${!combineArray[@]}"
do
	echo $i --- ${combineArray[$i]}
	if [ $(echo "$i" | egrep "ocean$") ]; then
		getAbort()
		{
                	printf "we do not create the zip-file for facet named 'ocean'\n"
		}
		getAbort
		trap 'getAbort; exit' SIGTERM
	else
		### Remove old version of project and zip-archives
		if [ ! -d $WORKSPACE/zip ]; then mkdir $WORKSPACE/zip; fi
		### Create zip-archive with application version for Windows
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
		time scp $WORKSPACE/zip/*$i-win*.zip jenkins@dev01.isd.dp.ua:$ARTIFACTS_DIR/${combineArray[$i]}/packages/artifacts/ && rm -f $WORKSPACE/zip/*$i-win*.zip
		rm -rf $WORKSPACE/zip
	fi
done
