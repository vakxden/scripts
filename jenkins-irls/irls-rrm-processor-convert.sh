if [ -z $PROCESSOR_COMMIT ]; then
	echo processor commit value not received
	exit 1
fi
if [ -z $SOURCES_COMMIT ]; then
	echo sources commit value not received
	exit 1
fi
### Variables
CURRENT_RRM=$HOME/irls-rrm-processor-deploy/$PROCESSOR_COMMIT
CURRENT_TEXTS=$HOME/irls-reader-current-texts/$SOURCES_COMMIT
RESULTS=$WORKSPACE/results
CURRENT_EPUBS=$HOME/irls-reader-current-epubs
TARGETS_REPO="git@wpp.isd.dp.ua:irls/targets.git"
TARGETS_REPO_DIR_NAME=$(echo $TARGETS_REPO | cut -d":" -f2 | cut -d"/" -f2 | sed s@.git@@g)
TARGET=($(echo $TARGET))
META1=$CURRENT_RRM/$PROCESSOR_COMMIT/meta-processor-deploy
META2=$CURRENT_TEXTS/$SOURCES_COMMIT/meta-ocean-deploy
META_SUM_ALL=meta-all

# Export variable for phantom
export NODE_PATH=/opt/node/lib/node_modules/
# Copy lib-processor code
cp -Rf $CURRENT_RRM/$PROCESSOR_COMMIT $WORKSPACE
cd $WORKSPACE/$PROCESSOR_COMMIT
# For monitoring
N=$(echo $BUILD_DISPLAY_NAME | sed 's/\#//g')
cat /dev/null > $WORKSPACE/filesconv.txt

###
### Running convert for all facets
###
for TARGET_NAME in "${TARGET[@]}"
do
        ### Clone or "git pull" (if exist) targets-repo
        if [ ! -d $WORKSPACE/$TARGETS_REPO_DIR_NAME ]; then
                cd $WORKSPACE && git clone $TARGETS_REPO
        else cd $WORKSPACE/$TARGETS_REPO_DIR_NAME && git pull
        fi
        ### Determine facet name from target
        FACET_NAME=$(grep facet $WORKSPACE/$TARGETS_REPO_DIR_NAME/$TARGET_NAME/targetConfig.json | awk -F'"|"' '{print $4}')
        ### Clean old "facet named"-directory
        rm -rf $RESULTS/$FACET_NAME
        mkdir -p $RESULTS/$FACET_NAME
        cd $WORKSPACE/$PROCESSOR_COMMIT/src
        ### Processing raw texts
        time node main.js -s $CURRENT_TEXTS/$SOURCES_COMMIT -d $RESULTS/$FACET_NAME -f $FACET_NAME -t $WORKSPACE/tmp
        time node --max-old-space-size=7000 $WORKSPACE/$PROCESSOR_COMMIT/src/createJSON.js $RESULTS/$FACET_NAME/
        ### Create (if not exist) current "target named"-, "current epub"-directory
        if [ ! -d $CURRENT_EPUBS/$TARGET_NAME ]; then mkdir -p $CURRENT_EPUBS/$TARGET_NAME; fi
        ### Copy epubs after their processing to the "current epubs"-directory
        time rsync -rv --delete $RESULTS/$FACET_NAME/ $CURRENT_EPUBS/$TARGET_NAME/
        ### Create file with summary meta-information
        META_SUM=meta-current-epubs-$TARGET_NAME
        cat $META1 >> $CURRENT_EPUBS/$TARGET_NAME/$META_SUM && cat $META2 >> $CURRENT_EPUBS/$TARGET_NAME/$META_SUM
        # echo numbers of converted files to temporary file
        files_conv=$(grep "Files converted.*$FACET_NAME" /var/lib/jenkins/jobs/irls-rrm-processor-convert/builds/$N/log | grep -v grep >> $WORKSPACE/filesconv.txt)
done

cat /dev/null > $CURRENT_EPUBS/$META_SUM_ALL
cat $META1 >> $CURRENT_EPUBS/$META_SUM_ALL && cat $META2 >> $CURRENT_EPUBS/$META_SUM_ALL

###
### Zabbix - generate graph for ocean facet
###
DATE=$(date +%s)
files_conv_ocean=$(grep ocean $WORKSPACE/filesconv.txt | awk '{print $6}')
if [ ! -z "$files_conv_ocean" ]; then
        zabbix_sender -z 127.0.0.1 p 10051 -s "dev01" -k files_conv_ocean -o "$files_conv_ocean"
fi

###
### Copy current epubs to jenkins nodes
###
for TARGET_NAME in "${TARGET[@]}"
do
        ### Clone or "git pull" (if exist) targets-repo
        if [ ! -d $WORKSPACE/$TARGETS_REPO_DIR_NAME ]; then
                cd $WORKSPACE && git clone $TARGETS_REPO
        else cd $WORKSPACE/$TARGETS_REPO_DIR_NAME && git pull
        fi
        ### Determine facet name from target
        FACET_NAME=$(grep facet $WORKSPACE/$TARGETS_REPO_DIR_NAME/$TARGET_NAME/targetConfig.json | awk -F'"|"' '{print $4}')
        ### Sync current "target named"-epubs to mac-mini ("yuriys-mac-mini" and "users-mac-mini"), if target config contain platform "ios"
        if grep "platforms.*ios" $WORKSPACE/$TARGETS_REPO_DIR_NAME/$TARGET_NAME/targetConfig.json; then
                ssh jenkins@yuriys-mac-mini.isd.dp.ua "if [ ! -d /Users/jenkins/irls-reader-current-epubs/$TARGET_NAME ]; then mkdir -p /Users/jenkins/irls-reader-current-epubs/$TARGET_NAME; fi"
                time rsync -rzv --delete --exclude "_oldjson" -e "ssh" $CURRENT_EPUBS/$TARGET_NAME/ jenkins@yuriys-mac-mini.isd.dp.ua:/Users/jenkins/irls-reader-current-epubs/$TARGET_NAME/
                ssh jenkins@users-mac-mini.design.isd.dp.ua "if [ ! -d /Users/jenkins/irls-reader-current-epubs/$TARGET_NAME ]; then mkdir -p /Users/jenkins/irls-reader-current-epubs/$TARGET_NAME; fi"
                time rsync -rzv --delete --exclude "_oldjson" -e "ssh" $CURRENT_EPUBS/$TARGET_NAME/ jenkins@users-mac-mini.design.isd.dp.ua:/Users/jenkins/irls-reader-current-epubs/$TARGET_NAME/
        fi
        ### Sync current "target named"-epubs to dev02.design.isd.dp.ua
        if [ "$FACET_NAME" = "ocean" ]; then
                printf "epubs for facet named 'ocean', target is $TARGET_NAME, will not be copying to dev02.design.isd.dp.ua \n"
        else
                ssh jenkins@dev02.design.isd.dp.ua "if [ ! -d ~/irls-reader-current-epubs/$TARGET_NAME ]; then mkdir -p ~/irls-reader-current-epubs/$TARGET_NAME; fi"
                time rsync -rzv --delete --exclude "_oldjson" -e "ssh" $CURRENT_EPUBS/$TARGET_NAME/ jenkins@dev02.design.isd.dp.ua:~/irls-reader-current-epubs/$TARGET_NAME/
        fi
done
###
### Remove from workspace
###
rm -rf $WORKSPACE/*
