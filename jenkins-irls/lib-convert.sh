###
### Remove all from workspace
###
rm -rf $WORKSPACE/*
### Variables
EPUBS_CACHE="$HOME/irls-reader-current-epubs/cache"
CURRENT_RRM=$PROCESSOR_CURRENT_CODE_PATH/$PROCESSOR_HASHCOMMIT
CURRENT_TEXTS=$SOURCES_CURRENT_CODE_PATH/$SOURCES_HASHCOMMIT
RESULTS=$WORKSPACE/results
CURRENT_EPUBS=$HOME/irls-reader-current-epubs/$PROCESSOR_BRANCHNAME
TARGETS_REPO="targets"
URL_TARGETS_JSON="http://wpp.isd.dp.ua/irls-reader-artifacts"
### Determine facet name from target
FACET_NAME=$(curl -s $URL_TARGETS_JSON/$TARGETS_REPO.json | grep '"target_name": "'$TARGET'"' | sed 's/^\(.*\)facet"//g' | awk -F '"|"' '{print $2}')
META1=$CURRENT_RRM/$PROCESSOR_META
META2=$CURRENT_TEXTS/$SOURCES_META

# Export variable for phantom
export NODE_PATH=/opt/node/lib/node_modules/
# Copy lib-processor code
if [ ! -d $WORKSPACE/$PROCESSOR_HASHCOMMIT ]; then mkdir -p $WORKSPACE/$PROCESSOR_HASHCOMMIT; fi
rsync -r $CURRENT_RRM/ $WORKSPACE/$PROCESSOR_HASHCOMMIT/
cd $WORKSPACE/$PROCESSOR_HASHCOMMIT
# For monitoring
N=$(echo $BUILD_DISPLAY_NAME | sed 's/\#//g')
cat /dev/null > $WORKSPACE/filesconv.txt

###
### Running convert for target
###
### Clean old "facet named"-directory
rm -rf $RESULTS/$FACET_NAME
mkdir -p $RESULTS/$FACET_NAME
cd $WORKSPACE/$PROCESSOR_HASHCOMMIT/src
### Processing raw texts
if [ $PROCESSOR_BRANCHNAME = "feature/conversion_result_caching" ]; then
        if [ ! -d $EPUBS_CACHE/$FACET_NAME ]; then mkdir -p $EPUBS_CACHE/$FACET_NAME; fi
        time node main.js -s $CURRENT_TEXTS -d $RESULTS/$FACET_NAME -f $FACET_NAME -c $EPUBS_CACHE/$FACET_NAME
else
        time node main.js -s $CURRENT_TEXTS -d $RESULTS/$FACET_NAME -f $FACET_NAME -t $WORKSPACE/tmp
fi
time node --max-old-space-size=7000 $WORKSPACE/$PROCESSOR_HASHCOMMIT/src/createJSON.js $RESULTS/$FACET_NAME/
### Create (if not exist) current "target named"-, "current epub"-directory
if [ ! -d $CURRENT_EPUBS/$TARGET ]; then mkdir -p $CURRENT_EPUBS/$TARGET; fi
### Copy epubs after their processing to the "current epubs"-directory
time rsync -r --delete --exclude="Report" $RESULTS/$FACET_NAME/ $CURRENT_EPUBS/$TARGET/
### Move reports
if [ ! -d $WORKSPACE/Report ]; then mkdir $WORKSPACE/Report; fi
time rsync -r --delete $RESULTS/$FACET_NAME/Report/ $WORKSPACE/Report/
ls -la $WORKSPACE/Report/*

### Create file with summary meta-information
META_SUM=$CURRENT_EPUBS/$TARGET/meta-current-epubs-$TARGET.json
echo '[' > $META_SUM
cat $META1 >> $META_SUM
echo "," >> $META_SUM
cat $META2 >> $META_SUM
echo ']' >> $META_SUM

# echo numbers of converted files to temporary file
files_conv=$(grep "Files converted.*$FACET_NAME" /var/lib/jenkins/jobs/$JOB_NAME/builds/$N/log | grep -v grep >> $WORKSPACE/filesconv.txt)


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
### Sync current "target named"-epubs to mac-mini ("yuriys-mac-mini" and "users-mac-mini"), if target config contain platform "ios"
if curl -s $URL_TARGETS_JSON/$TARGETS_REPO.json | grep '"target_name": "'$TARGET'"' | grep "platforms.*ios"; then
        ssh jenkins@yuriys-mac-mini.isd.dp.ua "if [ ! -d /Users/jenkins/irls-reader-current-epubs/$PROCESSOR_BRANCHNAME/$TARGET ]; then mkdir -p /Users/jenkins/irls-reader-current-epubs/$PROCESSOR_BRANCHNAME/$TARGET; fi"
        time rsync -rz --delete --exclude "_oldjson" -e "ssh" $CURRENT_EPUBS/$TARGET/ jenkins@yuriys-mac-mini.isd.dp.ua:/Users/jenkins/irls-reader-current-epubs/$PROCESSOR_BRANCHNAME/$TARGET/
        ssh jenkins@users-mac-mini.design.isd.dp.ua "if [ ! -d /Users/jenkins/irls-reader-current-epubs/$PROCESSOR_BRANCHNAME/$TARGET ]; then mkdir -p /Users/jenkins/irls-reader-current-epubs/$PROCESSOR_BRANCHNAME/$TARGET; fi"
        time rsync -rz --delete --exclude "_oldjson" -e "ssh" $CURRENT_EPUBS/$TARGET/ jenkins@users-mac-mini.design.isd.dp.ua:/Users/jenkins/irls-reader-current-epubs/$PROCESSOR_BRANCHNAME/$TARGET/
fi
### Sync current "target named"-epubs to dev02.design.isd.dp.ua
if curl -s $URL_TARGETS_JSON/$TARGETS_REPO.json | grep '"target_name": "'$TARGET'"' | grep "platforms.*android"; then
        ssh jenkins@dev02.design.isd.dp.ua "if [ ! -d $CURRENT_EPUBS/$TARGET ]; then mkdir -p $CURRENT_EPUBS/$TARGET; fi"
        time rsync -rz --delete --exclude "_oldjson" -e "ssh" $CURRENT_EPUBS/$TARGET/ jenkins@dev02.design.isd.dp.ua:$CURRENT_EPUBS/$TARGET/
fi
### For Summary+Display+Plugin
if [ ! -d /var/lib/jenkins/jobs/$JOB_NAME/builds/$BUILD_ID/archive ]; then mkdir -p /var/lib/jenkins/jobs/$JOB_NAME/builds/$BUILD_ID/archive; fi
cp $WORKSPACE/Report/Dict/*.xml /var/lib/jenkins/jobs/$JOB_NAME/builds/$BUILD_ID/archive/
