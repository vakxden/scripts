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
		rm -rf client packager server
		### Copy project to workspace
		if [ ! -d zip ]; then mkdir zip; fi
		# this line commented because this job was moved to host dev02.design.isd.dp.ua
		#cp -Rf $CURRENT_BUILD/$GIT_COMMIT/* .
		# this line there because this job working in host dev02.design.isd.dp.ua
		cp -Rf $CURRENT_BUILD/* .
		### Create zip-archive with application version for MacOS
		cd $WORKSPACE/packager
		node index.js --target=macos --config=/home/jenkins/build_config --from=$WORKSPACE/client --manifest=$WORKSPACE/client/package.json --prefix=$BRANCH- --suffix=-$i --epubs=$CURRENT_EPUBS/$i
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
		#cp $WORKSPACE/zip/*$i-macos*.zip $ARTIFACTS_DIR/${combineArray[$i]}/packages/artifacts/
		# this line there because this job working in host dev02.design.isd.dp.ua
		scp $WORKSPACE/zip/*$i-macos*.zip jenkins@dev01.isd.dp.ua:$ARTIFACTS_DIR/${combineArray[$i]}/packages/artifacts/
		rm -rf $WORKSPACE/zip
	fi
done
