### Variables
CURRENT_RRM=$HOME/irls-rrm-processor-deploy
CURRENT_TEXTS=$HOME/irls-reader-current-texts
RESULTS=$WORKSPACE/results
CURRENT_EPUBS=$HOME/irls-reader-current-epubs
TARGETS=($(echo $TARGET))
STATUS_FILE="/home/jenkins/irls-reader-artifacts/status.json"
PROCESSOR_REPONAME="lib-processor"
PROCESSOR_BRANCH="develop"
LAST_PROCESSOR_DEVELOP_COMMIT=$(grep $PROCESSOR_REPONAME $STATUS_FILE -A9| grep "branchName.*$PROCESSOR_BRANCH" -A1 | grep commit | awk -F '"|"' '{print $4}')
SOURCES_REPONAME="lib-sources"
LAST_SOURCES_MASTER_COMMIT=$(grep $SOURCES_REPONAME $STATUS_FILE -A2 | grep commit | awk -F '"|"' '{print $4}')

# from phantom
export NODE_PATH=/opt/node/lib/node_modules/


cp -Rf $CURRENT_RRM/$LAST_PROCESSOR_DEVELOP_COMMIT/* $WORKSPACE/
cd $WORKSPACE

###
### Running convert for all facets
###
for i in "${TARGETS[@]}"
do
        rm -rf $RESULTS/$i
        mkdir -p $RESULTS/$i
        cd $WORKSPACE/src
        node main.js $CURRENT_TEXTS/$LAST_SOURCES_MASTER_COMMIT $RESULTS/$i $i
        node --max-old-space-size=7000 $WORKSPACE/src/createJSON.js $RESULTS/$i/
        rm -rf $CURRENT_EPUBS/$i
        mkdir -p $CURRENT_EPUBS/$i
		if [ ! -d $CURRENT_EPUBS/$i ]; then
			mkdir -p $CURRENT_EPUBS/$i
		fi
        mv $RESULTS/$i/* $CURRENT_EPUBS/$i/
done

###
### Remove from workspace
###
rm -rf $WORKSPACE/*
