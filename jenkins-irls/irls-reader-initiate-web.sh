###
### Variables
###
ARTIFACTS_DIR=$HOME/irls-reader-artifacts
CURRENT_EPUBS=$HOME/irls-reader-current-epubs
FACETS=($(echo $FACET))
PREFIX=$(echo $BRANCHNAME | sed 's/\//-/g')
BUILD_CONFIG="$HOME/build_config"
###
### Copy project to workspace
###
rm -rf ./*
cp -Rf $CURRENT_BUILD/$GIT_COMMIT/* .
###
### Clone targets-repo
###
git clone git@wpp.isd.dp.ua:irls/targets.git
###
### Web-version with created index in couchdb
###
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
### Create web-version of application
for i in "${!combineArray[@]}"
do
	# $i - it is facet
	echo $i --- ${combineArray[$i]}
	cd $WORKSPACE/packager
	if [[ $BRANCHNAME == *target* ]]; then
		node index.js --target=web --brand=FFA --config=$BUILD_CONFIG --from=$WORKSPACE/client --manifest=$WORKSPACE/client/package.json --prefix=$PREFIX- --suffix=-$i --epubs=$CURRENT_EPUBS/$i/
	else
		node index.js --target=web --config=$BUILD_CONFIG --from=$WORKSPACE/client --manifest=$WORKSPACE/client/package.json --prefix=$PREFIX- --suffix=-$i --epubs=$CURRENT_EPUBS/$i/
	fi
	#create index
	cd $WORKSPACE
	sudo /home/jenkins/scripts/portgenerator-for-convert.sh $i
	cp local.json $WORKSPACE/server/config
	cd server
	node initDB.js
	if [ ! -d $ARTIFACTS_DIR/${combineArray[$i]}/packages ]; then
		mkdir -p $ARTIFACTS_DIR/${combineArray[$i]}/packages
	fi
	if [ ! -d $ARTIFACTS_DIR/${combineArray[$i]}/packages/client ]; then
		mkdir -p $ARTIFACTS_DIR/${combineArray[$i]}/packages/client
	fi
	if [ ! -d $ARTIFACTS_DIR/${combineArray[$i]}/packages/couchdb_indexes ]; then
		mkdir -p $ARTIFACTS_DIR/${combineArray[$i]}/packages/couchdb_indexes
	fi
	cp -Rf $WORKSPACE/common $ARTIFACTS_DIR/${combineArray[$i]}/packages/
	cp -Rf $WORKSPACE/server $ARTIFACTS_DIR/${combineArray[$i]}/packages/
	cp -Rf $WORKSPACE/portal $ARTIFACTS_DIR/${combineArray[$i]}/packages/
	cp -Rf $WORKSPACE/packager/out/dest/*/* $ARTIFACTS_DIR/${combineArray[$i]}/packages/client
	cp -Rf /home/couchdb/$i* $ARTIFACTS_DIR/${combineArray[$i]}/packages/couchdb_indexes
done
