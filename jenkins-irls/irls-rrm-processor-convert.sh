### Variables
CURRENT_RRM=$HOME/irls-rrm-processor-deploy
CURRENT_TEXTS=$HOME/irls-reader-current-texts
PROJECTNAME=$(basename $CURRENT_RRM)
RESULTS=$WORKSPACE/results
CURRENT_EPUBS=$HOME/irls-reader-current-epubs
FACETS=($(echo $FACET))
META1=$HOME/irls-rrm-processor-deploy/meta-processor-deploy
META2=$HOME/irls-reader-current-texts/meta-ocean-deploy
META_SUM_ALL=meta-all
# from phantom
export NODE_PATH=/opt/node/lib/node_modules/

cp -Rf $CURRENT_RRM $WORKSPACE
cd $WORKSPACE/$PROJECTNAME

N=$(echo $BUILD_DISPLAY_NAME | sed 's/\#//g')
cat /dev/null > $WORKSPACE/filesconv.txt

###
### Running convert for all facets
###
for i in "${FACETS[@]}"
do
	rm -rf $RESULTS/$i
	mkdir -p $RESULTS/$i
	cd $WORKSPACE/$PROJECTNAME/src
	time node main.js $CURRENT_TEXTS $RESULTS/$i $i
	time node --max-old-space-size=7000 $WORKSPACE/$PROJECTNAME/src/createJSON.js $RESULTS/$i/
	if [ ! -d $CURRENT_EPUBS/$i ]; then mkdir -p $CURRENT_EPUBS/$i; fi
	time rsync -rv --delete $RESULTS/$i/ $CURRENT_EPUBS/$i/
	META_SUM=meta-current-epubs-$i
	cat $META1 >> $CURRENT_EPUBS/$i/$META_SUM && cat $META2 >> $CURRENT_EPUBS/$i/$META_SUM
	# echo numbers of converted files to temporary file
	files_conv=$(grep "Files converted.*$i" /var/lib/jenkins/jobs/irls-rrm-processor-convert/builds/$N/log | grep -v grep >> $WORKSPACE/filesconv.txt)
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
for i in "${FACETS[@]}"
do
	### Sync current epubs to mac-mini
	if [ "$i" = "ocean" ]; then
		printf "epubs for facet named 'ocean' will not be copying to mac-mini \n"
	else
		ssh jenkins@yuriys-mac-mini.isd.dp.ua "if [ ! -d /Users/jenkins/irls-reader-current-epubs/$i ]; then mkdir -p /Users/jenkins/irls-reader-current-epubs/$i; fi"
		time rsync -rzv --delete --exclude "_oldjson" -e "ssh" ~/irls-reader-current-epubs/$i/ jenkins@yuriys-mac-mini.isd.dp.ua:/Users/jenkins/irls-reader-current-epubs/$i/
	fi

	### Sync current epubs to dev02.design.isd.dp.ua
	if [ "$i" = "ocean" ]; then
		printf "epubs for facet named 'ocean' will not be copying to dev02.design.isd.dp.ua \n"
	else
		ssh jenkins@dev02.design.isd.dp.ua "if [ ! -d ~/irls-reader-current-epubs/$i ]; then mkdir -p ~/irls-reader-current-epubs/$i; fi"
		time rsync -rzv --delete --exclude "_oldjson" -e "ssh" ~/irls-reader-current-epubs/$i/ jenkins@dev02.design.isd.dp.ua:~/irls-reader-current-epubs/$i/
	fi
done
###
### Remove from workspace
###
rm -rf $WORKSPACE/*
