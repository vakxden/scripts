### Variables
CURRENT_RRM=$HOME/irls-rrm-processor-deploy
CURRENT_TEXTS=$HOME/irls-reader-current-texts
PROJECTNAME=$(basename $CURRENT_RRM)
RESULTS=$WORKSPACE/results
CURRENT_EPUBS=$HOME/irls-reader-current-epubs
#FACETS=(puddle lake bahaiebooks ocean audio mediaoverlay)
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

### Before starting epubchecker (!)
#rm -f $WORKSPACE/epubcheck*.log

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
	rm -rf $CURRENT_EPUBS/$i
	mkdir -p $CURRENT_EPUBS/$i
	mv $RESULTS/$i/* $CURRENT_EPUBS/$i/
	META_SUM=meta-current-epubs-$i
	cat $META1 >> $CURRENT_EPUBS/$i/$META_SUM && cat $META2 >> $CURRENT_EPUBS/$i/$META_SUM
	# echo numbers of converted files to temporary file
	files_conv=$(grep "Files converted.*$i" /var/lib/jenkins/jobs/irls-rrm-processor-convert/builds/$N/log | grep -v grep >> $WORKSPACE/filesconv.txt)
	### Starting epubchecker
	#cd $WORKSPACE
	#/opt/epubcheck.sh $CURRENT_EPUBS/$i/
	# for set description (link to graph for ocean)
	if [ "$i" = "ocean" ]; then
		printf "WARN_OCEAN \n"
	fi
done

cat /dev/null > $CURRENT_EPUBS/$META_SUM_ALL
cat $META1 >> $CURRENT_EPUBS/$META_SUM_ALL && cat $META2 >> $CURRENT_EPUBS/$META_SUM_ALL

###
### RRDtool - generate graph for ocean facet
###
DATE=$(date +%s)
files_conv_ocean=$(grep ocean $WORKSPACE/filesconv.txt | awk '{print $6}')
if [ ! -z "$files_conv_ocean" ]; then
	sudo rrdtool update /var/db/rrdtool/trendcountbooks.rrd $DATE:$files_conv_ocean
	sudo rrdtool graph /home/jenkins/irls-reader-artifacts/trendcountbooks.png -a PNG -v "irls-rrm-processor-convert" --start now-14d --end N -w 1200 -h 400 DEF:numbers_of=/var/db/rrdtool/trendcountbooks.rrd:numbers_of:LAST AREA:numbers_of#00FF00:"Numbers of files converted"
fi

###
### Copy current epubs to jenkins nodes
###
for i in "${FACETS[@]}"
do
	# create tar.xz archive
	time tar cfJ $i.tar.xz ~/irls-reader-current-epubs/$i --exclude="_oldjson"
	
	###
	### Copy current epubs to mac-mini
	###
	#if [ "$i" = "ocean" ]; then
	#	printf "epubs for facet named 'ocean' will not be copying to mac-mini \n"
	#else
	#	ssh jenkins@yuriys-mac-mini.isd.dp.ua "
	#		if [ ! -d /Users/jenkins/irls-reader-current-epubs/$i ]; then mkdir /Users/jenkins/irls-reader-current-epubs/$i; fi
	#		rm -rf /Users/jenkins/irls-reader-current-epubs/$i/*
	#	"
	#	time scp $i.tar.xz jenkins@yuriys-mac-mini.isd.dp.ua:~
	#	ssh jenkins@yuriys-mac-mini.isd.dp.ua "
	#		tar xfJ $i.tar.xz -C /Users/jenkins/irls-reader-current-epubs/$i/
	#		mv /Users/jenkins/irls-reader-current-epubs/$i$CURRENT_EPUBS/$i/* /Users/jenkins/irls-reader-current-epubs/$i/ && rm -rf /Users/jenkins/irls-reader-current-epubs/$i/home
	#		rm -f $i.tar.xz
	#	"
	#fi

	###
	### Copy current epubs to devzone
	###
	ssh dvac@devzone.dp.ua "
		if [ ! -d ~/irls-reader-current-epubs/$i ]; then mkdir  ~/irls-reader-current-epubs/$i; fi
		rm -rf ~/irls-reader-current-epubs/$i/*
	"
	time scp $i.tar.xz dvac@devzone.dp.ua:~
	ssh dvac@devzone.dp.ua "
		tar xfJ $i.tar.xz -C ~/irls-reader-current-epubs/$i/
		mv ~/irls-reader-current-epubs/$i$CURRENT_EPUBS/$i/* ~/irls-reader-current-epubs/$i/ && rm -rf ~/irls-reader-current-epubs/$i/home
		rm -f $i.tar.xz
	"

	###
	### Copy current epubs to dev02.design.isd.dp.ua
	###
	ssh jenkins@dev02.design.isd.dp.ua "
		if [ ! -d ~/irls-reader-current-epubs/$i ]; then mkdir ~/irls-reader-current-epubs/$i; fi
		rm -rf ~/irls-reader-current-epubs/$i/*
	"
	time scp $i.tar.xz jenkins@dev02.design.isd.dp.ua:~
	ssh jenkins@dev02.design.isd.dp.ua "
		tar xfJ $i.tar.xz -C ~/irls-reader-current-epubs/$i/
		mv ~/irls-reader-current-epubs/$i$CURRENT_EPUBS/$i/* ~/irls-reader-current-epubs/$i/ && rm -rf ~/irls-reader-current-epubs/$i/home
		rm -f $i.tar.xz
	"
	
	# remove tar.xz archive
	rm -f $i.tar.xz
done
###
### Remove from workspace
###
rm -rf $WORKSPACE/*
