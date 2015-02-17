###
### Remove all from workspace
###
rm -rf $WORKSPACE/*
###
### Check values
###
if [ -z $PROCESSOR_COMMIT ]; then
        echo processor commit value not received
        exit 1
fi
if [ -z $SOURCES_COMMIT ]; then
        echo sources commit value not received
        exit 1
fi
### Variables
EPUBS_CACHE="$HOME/irls-reader-current-epubs/cache"
CURRENT_RRM=$HOME/irls-rrm-processor-deploy/$PROCESSOR_COMMIT
CURRENT_TEXTS=$HOME/irls-reader-current-texts/$SOURCES_COMMIT
RESULTS=$WORKSPACE/results
CURRENT_EPUBS=$HOME/irls-reader-current-epubs/$PROCESSOR_BRANCH
TARGETS_REPO="git@wpp.isd.dp.ua:irls/targets.git"
TARGETS_REPO_DIR_NAME=$(echo $TARGETS_REPO | cut -d":" -f2 | cut -d"/" -f2 | sed s@.git@@g)
TARGET=($(echo $TARGET))
META1=$CURRENT_RRM/meta-processor-deploy
META2=$CURRENT_TEXTS/meta-ocean-deploy
META_SUM_ALL=meta-all

# Export variable for phantom
export NODE_PATH=/opt/node/lib/node_modules/
# Copy lib-processor code
if [ ! -d $WORKSPACE/$PROCESSOR_COMMIT ]; then mkdir -p $WORKSPACE/$PROCESSOR_COMMIT; fi
rsync -r $CURRENT_RRM/ $WORKSPACE/$PROCESSOR_COMMIT/
#cp -Rf $CURRENT_RRM $WORKSPACE
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
	if [ $PROCESSOR_BRANCH = "feature/conversion_result_caching" ]; then
		time node main.js -s $CURRENT_TEXTS -d $RESULTS/$FACET_NAME -f $FACET_NAME -c $EPUBS_CACHE
        else 
		time node main.js -s $CURRENT_TEXTS -d $RESULTS/$FACET_NAME -f $FACET_NAME -t $WORKSPACE/tmp
	fi
        time node --max-old-space-size=7000 $WORKSPACE/$PROCESSOR_COMMIT/src/createJSON.js $RESULTS/$FACET_NAME/
        ### Create (if not exist) current "target named"-, "current epub"-directory
        if [ ! -d $CURRENT_EPUBS/$TARGET_NAME ]; then mkdir -p $CURRENT_EPUBS/$TARGET_NAME; fi
        ### Copy epubs after their processing to the "current epubs"-directory
        time rsync -r --delete --exclude="Report" $RESULTS/$FACET_NAME/ $CURRENT_EPUBS/$TARGET_NAME/
        ### Move reports
        if [ ! -d $WORKSPACE/Report ]; then mkdir $WORKSPACE/Report; fi
        time rsync -r --delete $RESULTS/$FACET_NAME/Report/ $WORKSPACE/Report/
        ls -la $WORKSPACE/Report/*
        ### Create file with summary meta-information
        META_SUM=meta-current-epubs-$TARGET_NAME
        cat $META1 >> $CURRENT_EPUBS/$TARGET_NAME/$META_SUM && cat $META2 >> $CURRENT_EPUBS/$TARGET_NAME/$META_SUM
        # echo numbers of converted files to temporary file
        files_conv=$(grep "Files converted.*$FACET_NAME" /var/lib/jenkins/jobs/$JOB_NAME/builds/$N/log | grep -v grep >> $WORKSPACE/filesconv.txt)
        cat /dev/null > $CURRENT_EPUBS/$TARGET_NAME/$META_SUM_ALL
        cat $META1 >> $CURRENT_EPUBS/$TARGET_NAME/$META_SUM_ALL && cat $META2 >> $CURRENT_EPUBS/$TARGET_NAME/$META_SUM_ALL
done


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
                ssh jenkins@yuriys-mac-mini.isd.dp.ua "if [ ! -d /Users/jenkins/irls-reader-current-epubs/$PROCESSOR_BRANCH/$TARGET_NAME ]; then mkdir -p /Users/jenkins/irls-reader-current-epubs/$PROCESSOR_BRANCH/$TARGET_NAME; fi"
                time rsync -rzv --delete --exclude "_oldjson" -e "ssh" $CURRENT_EPUBS/$TARGET_NAME/ jenkins@yuriys-mac-mini.isd.dp.ua:/Users/jenkins/irls-reader-current-epubs/$PROCESSOR_BRANCH/$TARGET_NAME/
                ssh jenkins@users-mac-mini.design.isd.dp.ua "if [ ! -d /Users/jenkins/irls-reader-current-epubs/$PROCESSOR_BRANCH/$TARGET_NAME ]; then mkdir -p /Users/jenkins/irls-reader-current-epubs/$PROCESSOR_BRANCH/$TARGET_NAME; fi"
                time rsync -rzv --delete --exclude "_oldjson" -e "ssh" $CURRENT_EPUBS/$TARGET_NAME/ jenkins@users-mac-mini.design.isd.dp.ua:/Users/jenkins/irls-reader-current-epubs/$PROCESSOR_BRANCH/$TARGET_NAME/
        fi
        ### Sync current "target named"-epubs to dev02.design.isd.dp.ua
        if [ "$FACET_NAME" = "ocean" ]; then
                printf "epubs for facet named 'ocean', target is $TARGET_NAME, will not be copying to dev02.design.isd.dp.ua \n"
        else
                ssh jenkins@dev02.design.isd.dp.ua "if [ ! -d $CURRENT_EPUBS/$TARGET_NAME ]; then mkdir -p $CURRENT_EPUBS/$TARGET_NAME; fi"
                time rsync -rzv --delete --exclude "_oldjson" -e "ssh" $CURRENT_EPUBS/$TARGET_NAME/ jenkins@dev02.design.isd.dp.ua:$CURRENT_EPUBS/$TARGET_NAME/
        fi
done
### For Summary+Display+Plugin
if [ ! -d /var/lib/jenkins/jobs/$JOB_NAME/builds/$BUILD_ID/archive ]; then mkdir -p /var/lib/jenkins/jobs/$JOB_NAME/builds/$BUILD_ID/archive; fi
cp $WORKSPACE/Report/Dict/*.xml /var/lib/jenkins/jobs/$JOB_NAME/builds/$BUILD_ID/archive/
