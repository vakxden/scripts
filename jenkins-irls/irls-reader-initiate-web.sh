### Variables
ARTIFACTS_DIR=$HOME/irls-reader-artifacts
CURRENT_EPUBS=$HOME/irls-reader-current-epubs
FACETS=($(echo $FACET))
PREFIX=$(echo $BRANCHNAME | sed 's/\//-/g')
BUILD_CONFIG="$HOME/build_config"
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
		time node index.js --platform=web --config=$WORKSPACE/targets --from=$WORKSPACE/client --manifest=$WORKSPACE/client/package.json --prefix=$PREFIX- --epubs=$CURRENT_EPUBS
		#create index
		cd $WORKSPACE
		sudo $SCRIPTS_DIR/portgenerator-for-convert.sh $i
		cp local.json $WORKSPACE/server/config && rm -f local.json
		cd $WORKSPACE/server
		time node initDB.js
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
		ls -l /home/couchdb/"$i"_*.couch
		#sudo service couchdb restart
		ls -l /home/couchdb/"$i"_*.couch
		sleep 15
		ls -l /home/couchdb/"$i"_*.couch
		cp -f /home/couchdb/"$i"_books.couch $ARTIFACTS_DIR/${combineArray[$i]}/packages/couchdb_indexes/ && ls -l $ARTIFACTS_DIR/${combineArray[$i]}/packages/couchdb_indexes/
		cp -f /home/couchdb/"$i"_sentences.couch $ARTIFACTS_DIR/${combineArray[$i]}/packages/couchdb_indexes/ && ls -l $ARTIFACTS_DIR/${combineArray[$i]}/packages/couchdb_indexes/
		cp -f /home/couchdb/"$i"_words.couch $ARTIFACTS_DIR/${combineArray[$i]}/packages/couchdb_indexes/ && ls -l $ARTIFACTS_DIR/${combineArray[$i]}/packages/couchdb_indexes/
		ls -l $ARTIFACTS_DIR/${combineArray[$i]}/packages/couchdb_indexes/
		sleep 10
		ls -l $ARTIFACTS_DIR/${combineArray[$i]}/packages/couchdb_indexes/
		MD5SUM_BOOKS_COUCH=$(md5sum /home/couchdb/"$i"_books.couch | awk '{print $1}')
		MD5SUM_BOOKS_COPYED=$(md5sum $ARTIFACTS_DIR/${combineArray[$i]}/packages/couchdb_indexes/"$i"_books.couch | awk '{print $1}')
		if ! [ "$MD5SUM_BOOKS_COUCH" = "$MD5SUM_BOOKS_COPYED" ]; then
			echo "md5sum of copyed '$i'_books.couch not equal"
			exit 1
		fi
		MD5SUM_SENTENCES_COUCH=$(md5sum /home/couchdb/"$i"_sentences.couch | awk '{print $1}')
		MD5SUM_SENTENCES_COPYED=$(md5sum $ARTIFACTS_DIR/${combineArray[$i]}/packages/couchdb_indexes/"$i"_sentences.couch | awk '{print $1}')
		if ! [ "$MD5SUM_SENTENCES_COUCH" = "$MD5SUM_SENTENCES_COPYED" ]; then
			echo "md5sum of copyed '$i'_sentences.couch not equal"
			exit 1
		fi
		MD5SUM_WORDS_COUCH=$(md5sum /home/couchdb/"$i"_words.couch | awk '{print $1}')
		MD5SUM_WORDS_COPYED=$(md5sum $ARTIFACTS_DIR/${combineArray[$i]}/packages/couchdb_indexes/"$i"_words.couch | awk '{print $1}')
		if ! [ "$MD5SUM_WORDS_COUCH" = "$MD5SUM_WORDS_COPYED" ]; then
			echo "md5sum of copyed '$i'_words.couch not equal"
			echo "[ERROR_MD5] Error of md5sum!"
			exit 1
		fi
		### Check text clustering
#		cd $WORKSPACE
#		git clone git@wpp.isd.dp.ua:irls/rrm-processor.git
#		cd $WORKSPACE/rrm-processor
#		git checkout feature-texts-clustering
#		cd $WORKSPACE/rrm-processor/src
#		node main_metainfo.js $CURRENT_EPUBS/$i http://localhost:5984 $i
	}
	for i in "${!combineArray[@]}"
	do
	
		rm -rf $WORKSPACE/*
		if [ "$i" = "ocean" ]; then BRAND="$i"_"Ocean"; else BRAND="$i"_"FFA"; fi
		GIT_COMMIT_TARGET="$GIT_COMMIT"-"$BRAND"
		cp -Rf $CURRENT_BUILD/$GIT_COMMIT_TARGET/* $WORKSPACE/
	
		echo $i --- ${combineArray[$i]}
		### Checking contain platform
		if grep "platforms.*web" $WORKSPACE/targets/$BRAND/targetConfig.json; then
			notmainloop
		else
			echo "Shutdown of this job because platform \"web\" not found in config targetConfig.json"
			exit 0
		fi
	done
}

main_loop
