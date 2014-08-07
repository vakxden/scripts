### This job should take such variables as READER_BRANCH_NAME, READER_COMMIT_HASH, NIGHTLY_BUILD, ID, FACET, NIGHTLY_ARTIFACTS_DIR, ENVIRONMENT, NIGHTLY_EPUBS

### Variables
FACETS=($(echo $FACET))
PREFIX=$(echo $READER_BRANCH_NAME | sed 's/\//-/g')
SCRIPTS_DIR="$HOME/scripts"
deploymentPackageId=($(echo $ID))
declare -A combineArray

### Create associative array
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
function main_loop {
        notmainloop ()
        {
                cd $WORKSPACE/packager
                time node index.js --platform=web --config=$WORKSPACE/targets --from=$WORKSPACE/client --manifest=$WORKSPACE/client/package.json --prefix=$PREFIX- --epubs=$NIGHTLY_EPUBS
                #create index
                cd $WORKSPACE
                sudo $SCRIPTS_DIR/portgenerator-for-convert.sh $i
                cp local.json $WORKSPACE/server/config && rm -f local.json
                cd $WORKSPACE/server
                time node initDB.js
                if [ ! -d $NIGHTLY_ARTIFACTS_DIR/${combineArray[$i]}/packages ]; then
                        mkdir -p $NIGHTLY_ARTIFACTS_DIR/${combineArray[$i]}/packages
                fi
                if [ ! -d $NIGHTLY_ARTIFACTS_DIR/${combineArray[$i]}/packages/client ]; then
                        mkdir -p $NIGHTLY_ARTIFACTS_DIR/${combineArray[$i]}/packages/client
                fi
                if [ ! -d $NIGHTLY_ARTIFACTS_DIR/${combineArray[$i]}/packages/couchdb_indexes ]; then
                        mkdir -p $NIGHTLY_ARTIFACTS_DIR/${combineArray[$i]}/packages/couchdb_indexes
                fi
                cp -Rf $WORKSPACE/common $NIGHTLY_ARTIFACTS_DIR/${combineArray[$i]}/packages/
                cp -Rf $WORKSPACE/server $NIGHTLY_ARTIFACTS_DIR/${combineArray[$i]}/packages/
                cp -Rf $WORKSPACE/portal $NIGHTLY_ARTIFACTS_DIR/${combineArray[$i]}/packages/
                cp -Rf $WORKSPACE/packager/out/dest/*/* $NIGHTLY_ARTIFACTS_DIR/${combineArray[$i]}/packages/client
                cp -Rf /home/couchdb/$i* $NIGHTLY_ARTIFACTS_DIR/${combineArray[$i]}/packages/couchdb_indexes
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
                GIT_COMMIT_TARGET=$(echo "$READER_COMMIT_HASH"-"$i"_"FFA")
                cp -Rf $NIGHTLY_BUILD/$GIT_COMMIT_TARGET/* $WORKSPACE/

                echo $i --- ${combineArray[$i]}
                ### Checking
                if [ "$READER_BRANCH_NAME" = "feature/platforms-config" ]; then
                        if grep "platforms.*web" $WORKSPACE/targets/"$i"_"FFA"/targetConfig.json; then
                                notmainloop
                        else
                                echo "Shutdown of this job because platform \"web\" not found in config targetConfig.json"
                                exit 0
                        fi
                else
                        notmainloop
                fi
        done
}

main_loop
