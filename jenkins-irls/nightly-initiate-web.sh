### This job should take such variables as READER_BRANCH_NAME, READER_COMMIT_HASH, NIGHTLY_BUILD, ID, TARGET, NIGHTLY_ARTIFACTS_DIR, ENVIRONMENT, NIGHTLY_EPUBS

### Variables
TARGET=($(echo $TARGET))
PREFIX=$(echo $READER_BRANCH_NAME | sed 's/\//-/g')
SCRIPTS_DIR="$HOME/scripts"
deploymentPackageId=($(echo $ID))
declare -A combineArray

### Create associative array
for ((i=0; i<${#deploymentPackageId[@]}; i++))
do
        for ((y=0; y<${#TARGET[@]}; y++))
        do
                if [ -n "$(echo "${deploymentPackageId[i]}" | grep "${TARGET[y]}$")" ]; then
                        combineArray+=(["${TARGET[y]}"]="${deploymentPackageId[i]}")
                fi
        done
done
### Create web-version of application
function main_loop {
        notmainloop ()
        {
                cd $WORKSPACE/packager
                time node index.js --platform=web --config=$WORKSPACE/targets --from=$WORKSPACE/client --manifest=$WORKSPACE/client/package.json --prefix=$PREFIX- --epubs=$NIGHTLY_EPUBS
                #create index
                cd $WORKSPACE
                #sudo $SCRIPTS_DIR/portgenerator-for-night-convert.sh $i
                #cp local.json $WORKSPACE/server/config && rm -f local.json
                #cd $WORKSPACE/server
                #time node initDB.js
                if [ ! -d $NIGHTLY_ARTIFACTS_DIR/${combineArray[$i]}/packages ]; then
                        mkdir -p $NIGHTLY_ARTIFACTS_DIR/${combineArray[$i]}/packages
                fi
                #if [ ! -d $NIGHTLY_ARTIFACTS_DIR/${combineArray[$i]}/packages/couchdb_indexes ]; then
                #        mkdir -p $NIGHTLY_ARTIFACTS_DIR/${combineArray[$i]}/packages/couchdb_indexes
                #fi
                #cp -Rf $WORKSPACE/common $NIGHTLY_ARTIFACTS_DIR/${combineArray[$i]}/packages/
                #cp -Rf $WORKSPACE/server $NIGHTLY_ARTIFACTS_DIR/${combineArray[$i]}/packages/
                #cp -Rf $WORKSPACE/portal $NIGHTLY_ARTIFACTS_DIR/${combineArray[$i]}/packages/
                #cp -Rf $WORKSPACE/books $NIGHTLY_ARTIFACTS_DIR/${combineArray[$i]}/packages/
		time rsync -rzv --delete --exclude "tests" --exclude "packager" --exclude "targets" --exclude "myenv" --exclude "Gruntfile.js" $WORKSPACE/ $ARTIFACTS_DIR/${combineArray[$i]}/packages/
                if [ ! -d $NIGHTLY_ARTIFACTS_DIR/${combineArray[$i]}/packages/client ]; then
                        mkdir -p $NIGHTLY_ARTIFACTS_DIR/${combineArray[$i]}/packages/client
                fi
                cp -Rf $WORKSPACE/packager/out/dest/*/* $NIGHTLY_ARTIFACTS_DIR/${combineArray[$i]}/packages/client/
                #cp -Rf /home/couchdb/"$i"_night $NIGHTLY_ARTIFACTS_DIR/${combineArray[$i]}/packages/couchdb_indexes/
                ### Check text clustering
#               cd $WORKSPACE
#               git clone git@wpp.isd.dp.ua:irls/rrm-processor.git
#               cd $WORKSPACE/rrm-processor
#               git checkout feature-texts-clustering
#               cd $WORKSPACE/rrm-processor/src
#               node main_metainfo.js $NIGHTLY_EPUBS/$i http://localhost:5984 $i
        }
        for i in "${!combineArray[@]}"
        do

                rm -rf $WORKSPACE/*
                GIT_COMMIT_TARGET=$(echo "$READER_COMMIT_HASH"-"$i")
                cp -Rf $NIGHTLY_BUILD/$GIT_COMMIT_TARGET/* $WORKSPACE/

                echo $i --- ${combineArray[$i]}
                ### Checking
		if grep "platforms.*web" $WORKSPACE/targets/$i/targetConfig.json; then
			notmainloop
		else
			echo "Shutdown of this job because platform \"web\" not found in config targetConfig.json"
			exit 0
		fi
        done
}

main_loop
