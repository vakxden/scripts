### Variables
RESULTS=$WORKSPACE/results
RRM_PROCESSOR_REPO_NAME="lib-processor"
RRM_PROCESSOR_BRANCH_NAME="develop"
RRM_OCEAN_REPO_NAME="lib-sources"
RRM_OCEAN_BRANCH_NAME="master"
READER_REPO_NAME="product"
READER_BRANCH_NAME="develop"
TARGETS_REPO="git@wpp.isd.dp.ua:irls/targets.git"
TARGETS_REPO_DIR_NAME=$(echo $TARGETS_REPO | cut -d":" -f2 | cut -d"/" -f2 | sed s@.git@@g)
TARGETS_BRANCH_NAME="master"
TARGET=(ffa ocean irls-audio irls-audiobywords irls-ocean)
NIGHTLY_EPUBS="$HOME/irls-reader-nightly-epubs"
NIGHTLY_MACMINI_EPUBS="/Users/jenkins/irls-reader-nightly-epubs"
NIGHTLY_ARTIFACTS_DIR="/home/jenkins/irls-reader-artifacts-nightly"
NIGHTLY_BUILD="/home/jenkins/irls-reader-nightly-build"
NIGHTLY_REMOTE_BUILD="/Users/jenkins/irls-reader-nightly-build"
ENVIRONMENT="NIGHT"

### Check exists directory
if [ ! -d "$NIGHTLY_EPUBS" ]; then mkdir $NIGHTLY_EPUBS; fi
if [ ! -d "$NIGHTLY_ARTIFACTS_DIR" ]; then mkdir -p $NIGHTLY_ARTIFACTS_DIR; fi

### git operations
if [ ! -d "$WORKSPACE/$RRM_PROCESSOR_REPO_NAME" ]; then
        cd $WORKSPACE && git clone git@wpp.isd.dp.ua:irls/"$RRM_PROCESSOR_REPO_NAME".git && cd $WORKSPACE/$RRM_PROCESSOR_REPO_NAME && git checkout $RRM_PROCESSOR_BRANCH_NAME
else
        cd $WORKSPACE/$RRM_PROCESSOR_REPO_NAME && git pull && git checkout $RRM_PROCESSOR_BRANCH_NAME
fi

if [ ! -d "$WORKSPACE/$RRM_OCEAN_REPO_NAME" ]; then
        cd $WORKSPACE && git clone git@wpp.isd.dp.ua:irls/"$RRM_OCEAN_REPO_NAME".git && cd $WORKSPACE/$RRM_OCEAN_REPO_NAME  && git checkout $RRM_OCEAN_BRANCH_NAME
else
        cd $WORKSPACE/$RRM_OCEAN_REPO_NAME && git pull && git checkout $RRM_OCEAN_BRANCH_NAME
fi

if [ ! -d "$WORKSPACE/$READER_REPO_NAME" ]; then
        cd $WORKSPACE && git clone git@wpp.isd.dp.ua:irls/"$READER_REPO_NAME".git && cd $WORKSPACE/$READER_REPO_NAME && git checkout $READER_BRANCH_NAME
else
        cd $WORKSPACE/$READER_REPO_NAME && git pull && git checkout $READER_BRANCH_NAME
fi

if [ ! -d "$WORKSPACE/$TARGETS_REPO_DIR_NAME" ]; then
        cd $WORKSPACE && git clone $TARGETS_REPO && cd $WORKSPACE/$TARGETS_REPO_DIR_NAME && git checkout $TARGETS_BRANCH_NAME
else
        cd $WORKSPACE/$TARGETS_REPO_DIR_NAME && git pull && git checkout $TARGETS_BRANCH_NAME
fi

### Convert
# from phantom
export NODE_PATH=/opt/node/lib/node_modules/
if ps aux | grep node.*main.js | grep -v grep; then echo "node main.js is executing"; fi
for TARGET_NAME in ${TARGET[@]}
do
	### Clone or "git pull" (if exist) targets-repo
	if [ ! -d $WORKSPACE/$TARGETS_REPO_DIR_NAME ]; then
		cd $WORKSPACE && git clone $TARGETS_REPO
	else cd $WORKSPACE/$TARGETS_REPO_DIR_NAME && git pull
	fi
	### Determine facet name from target
	FACET_NAME=$(grep facet $WORKSPACE/$TARGETS_REPO_DIR_NAME/$TARGET_NAME/targetConfig.json | awk -F'"|"' '{print $4}')
	if [ -z $FACET_NAME ]; then echo "FACET_NAME is not determined!" && exit 1; fi
	### Clean old "facet named"-directory
	rm -rf $RESULTS/$FACET_NAME
	mkdir -p $RESULTS/$FACET_NAME
	cd $WORKSPACE/$RRM_PROCESSOR_REPO_NAME/src
	### Processing raw texts
	time node main.js $WORKSPACE/$RRM_OCEAN_REPO_NAME $RESULTS/$FACET_NAME $FACET_NAME
	time node --max-old-space-size=7000 $WORKSPACE/$RRM_PROCESSOR_REPO_NAME/src/createJSON.js $RESULTS/$FACET_NAME/
	### Create (if not exist) current "target named"-, "current epub"-directory
	if [ ! -d $NIGHTLY_EPUBS/$TARGET_NAME ]; then mkdir -p $NIGHTLY_EPUBS/$TARGET_NAME; fi
	### Copy epubs after their processing to the "current epubs"-directory
	time rsync -rv --delete $RESULTS/$FACET_NAME/ $NIGHTLY_EPUBS/$TARGET_NAME/
done

### Copy current epubs to jenkins nodes
for TARGET_NAME in "${TARGET[@]}"
do
	### Clone or "git pull" (if exist) targets-repo
	if [ ! -d $WORKSPACE/$TARGETS_REPO_DIR_NAME ]; then
		cd $WORKSPACE && git clone $TARGETS_REPO
	else cd $WORKSPACE/$TARGETS_REPO_DIR_NAME && git pull
	fi
	### Determine facet name from target
	FACET_NAME=$(grep facet $WORKSPACE/$TARGETS_REPO_DIR_NAME/$TARGET_NAME/targetConfig.json | awk -F'"|"' '{print $4}')
	if [ -z $FACET_NAME ]; then echo "FACET_NAME is not determined!" && exit 1; fi
	### Sync current "target named"-epubs to mac-mini ("yuriys-mac-mini" and "users-mac-mini"), if target config contain platform "ios"
	if grep "platforms.*ios" $WORKSPACE/$TARGETS_REPO_DIR_NAME/$TARGET_NAME/targetConfig.json; then
		ssh jenkins@yuriys-mac-mini.isd.dp.ua "if [ ! -d $NIGHTLY_MACMINI_EPUBS/$TARGET_NAME ]; then mkdir -p $NIGHTLY_MACMINI_EPUBS/$TARGET_NAME; fi"
		time rsync -rzv --delete --exclude "_oldjson" -e "ssh" $NIGHTLY_EPUBS/$TARGET_NAME/ jenkins@yuriys-mac-mini.isd.dp.ua:$NIGHTLY_MACMINI_EPUBS/$TARGET_NAME/
		ssh jenkins@users-mac-mini.design.isd.dp.ua "if [ ! -d $NIGHTLY_MACMINI_EPUBS/$TARGET_NAME ]; then mkdir -p $NIGHTLY_MACMINI_EPUBS/$TARGET_NAME; fi"
		time rsync -rzv --delete --exclude "_oldjson" -e "ssh" $NIGHTLY_EPUBS/$TARGET_NAME/ jenkins@users-mac-mini.design.isd.dp.ua:$NIGHTLY_MACMINI_EPUBS/$TARGET_NAME/
	fi
	### Sync current "target named"-epubs to dev02.design.isd.dp.ua
	if grep "platforms.*android" $WORKSPACE/$TARGETS_REPO_DIR_NAME/$TARGET_NAME/targetConfig.json; then
		ssh jenkins@dev02.design.isd.dp.ua "if [ ! -d $NIGHTLY_EPUBS/$TARGET_NAME ]; then mkdir -p $NIGHTLY_EPUBS/$TARGET_NAME; fi"
		time rsync -rzv --delete --exclude "_oldjson" -e "ssh" $NIGHTLY_EPUBS/$TARGET_NAME/ jenkins@dev02.design.isd.dp.ua:$NIGHTLY_EPUBS/$TARGET_NAME/
	fi
done

### Create variables for meta.json
# rrm-processor
cd $WORKSPACE/$RRM_PROCESSOR_REPO_NAME
RRM_PROCESSOR_COMMIT_MESSAGE=$(git log -1 --pretty=format:"%s")
RRM_PROCESSOR_COMMIT_DATE=$(git log -1 --pretty=format:"%ci")
RRM_PROCESSOR_COMMITTER_NAME=$(git log -1 --pretty=format:"%cn")
RRM_PROCESSOR_COMMITTER_EMAIL=$(git log -1 --pretty=format:"%ce")
RRM_PROCESSOR_COMMIT_HASH=$(git log -1 --pretty=format:"%H")
RRM_PROCESSOR_SHORT_COMMIT_HASH=$(git log -1 --pretty=format:"%h")
RRM_PROCESSOR_COMMIT_URL="http://wpp.isd.dp.ua/gitlab/irls/$RRM_PROCESSOR_REPO_NAME/commit/$RRM_PROCESSOR_COMMIT_HASH"
# rrm-ocean
cd $WORKSPACE/$RRM_OCEAN_REPO_NAME
RRM_OCEAN_COMMIT_MESSAGE=$(git log -1 --pretty=format:"%s")
RRM_OCEAN_COMMIT_DATE=$(git log -1 --pretty=format:"%ci")
RRM_OCEAN_COMMITTER_NAME=$(git log -1 --pretty=format:"%cn")
RRM_OCEAN_COMMITTER_EMAIL=$(git log -1 --pretty=format:"%ce")
RRM_OCEAN_COMMIT_HASH=$(git log -1 --pretty=format:"%H")
RRM_OCEAN_SHORT_COMMIT_HASH=$(git log -1 --pretty=format:"%h")
RRM_OCEAN_COMMIT_URL="http://wpp.isd.dp.ua/gitlab/irls/$RRM_OCEAN_REPO_NAME/commit/$RRM_OCEAN_COMMIT_HASH"
# product (old reader)
cd $WORKSPACE/$READER_REPO_NAME
READER_COMMIT_MESSAGE=$(git log -1 --pretty=format:"%s")
READER_COMMIT_DATE=$(git log -1 --pretty=format:"%ci")
READER_COMMITTER_NAME=$(git log -1 --pretty=format:"%cn")
READER_COMMITTER_EMAIL=$(git log -1 --pretty=format:"%ce")
READER_COMMIT_HASH=$(git log -1 --pretty=format:"%H")
READER_SHORT_COMMIT_HASH=$(git log -1 --pretty=format:"%h")
READER_COMMIT_URL="http://wpp.isd.dp.ua/gitlab/irls/$READER_REPO_NAME/commit/$READER_COMMIT_HASH"

### Generate deploymentPackageId array
deploymentPackageId=()
for i in "${TARGET[@]}"
do
        deploymentPackageId=("${deploymentPackageId[@]}" "$(echo "$READER_SHORT_COMMIT_HASH$RRM_PROCESSOR_SHORT_COMMIT_HASH$RRM_OCEAN_SHORT_COMMIT_HASH"_"$i")")
done

### Create meta.json
for i in ${deploymentPackageId[@]}
do
        echo "numbers of element in array deploymentPackageId=${#deploymentPackageId[@]}"
        ### check exists directory $NIGHTLY_ARTIFACTS_DIR/$i
        if [ ! -d $NIGHTLY_ARTIFACTS_DIR/$i ]; then mkdir -p $NIGHTLY_ARTIFACTS_DIR/$i; fi
	### Determine facet name
        TARGET_NAME=$(echo $i | sed 's@^.[0-9a-z]*_@@g')
        function create_meta {
                echo "Starting of function create_meta with variables $1 and $2"
                ### $1 - it is deploymentPackageId
                ### $2 - it is TARGET_NAME
                CURRENT_META_JSON=""
                CURRENT_META_JSON=$NIGHTLY_ARTIFACTS_DIR/$1/meta.json
                echo CURRENT_META_JSON=$CURRENT_META_JSON
                echo -e "{" >> $CURRENT_META_JSON
                echo -e "\t\"buildID\":\""$1"\"," >> $CURRENT_META_JSON
                echo -e "\t\"targetName\":\""$2"\"," >> $CURRENT_META_JSON
                echo -e "\t\"buildURL\":\""$BUILD_URL"\"," >> $CURRENT_META_JSON
                echo -e "\t\"commitDate\":\""$READER_COMMIT_DATE"\"," >> $CURRENT_META_JSON
                echo -e "\t\"rrm-processor\" : {" >> $CURRENT_META_JSON
                echo -e "\t\t\"commitID\":\""$RRM_PROCESSOR_COMMIT_HASH"\"," >> $CURRENT_META_JSON
                echo -e "\t\t\"commitMessage\":\""$RRM_PROCESSOR_COMMIT_MESSAGE"\"," >> $CURRENT_META_JSON
                echo -e "\t\t\"branchName\":\""$RRM_PROCESSOR_BRANCH_NAME"\"," >> $CURRENT_META_JSON
                echo -e "\t\t\"commitAuthor\":\""$RRM_PROCESSOR_COMMITTER_NAME"\"," >> $CURRENT_META_JSON
                echo -e "\t\t\"commitDate\":\""$RRM_PROCESSOR_COMMIT_DATE"\"," >> $CURRENT_META_JSON
                echo -e "\t\t\"email\":\""$RRM_PROCESSOR_COMMITTER_EMAIL"\"," >> $CURRENT_META_JSON
                echo -e "\t\t\"commitURL\":\""$RRM_PROCESSOR_COMMIT_URL"\"" >> $CURRENT_META_JSON
                echo -e "\t}," >> $CURRENT_META_JSON
                echo -e "\t\"rrm-ocean\" : {" >> $CURRENT_META_JSON
                echo -e "\t\t\"commitID\":\""$RRM_OCEAN_COMMIT_HASH"\"," >> $CURRENT_META_JSON
                echo -e "\t\t\"commitMessage\":\""$RRM_OCEAN_COMMIT_MESSAGE"\"," >> $CURRENT_META_JSON
                echo -e "\t\t\"branchName\":\""$RRM_OCEAN_BRANCH_NAME"\"," >> $CURRENT_META_JSON
                echo -e "\t\t\"commitAuthor\":\""$RRM_OCEAN_COMMITTER_NAME"\"," >> $CURRENT_META_JSON
                echo -e "\t\t\"commitDate\":\""$RRM_OCEAN_COMMIT_DATE"\"," >> $CURRENT_META_JSON
                echo -e "\t\t\"email\":\""$RRM_OCEAN_COMMITTER_EMAIL"\"," >> $CURRENT_META_JSON
                echo -e "\t\t\"commitURL\":\""$RRM_OCEAN_COMMIT_URL"\"" >> $CURRENT_META_JSON
                echo -e "\t}," >> $CURRENT_META_JSON
                echo -e "\t\"reader\" : {" >> $CURRENT_META_JSON
                echo -e "\t\t\"commitID\":\""$READER_COMMIT_HASH"\"," >> $CURRENT_META_JSON
                echo -e "\t\t\"commitMessage\":\""$READER_COMMIT_MESSAGE"\"," >> $CURRENT_META_JSON
                echo -e "\t\t\"branchName\":\""$READER_BRANCH_NAME"\"," >> $CURRENT_META_JSON
                echo -e "\t\t\"commitAuthor\":\""$READER_COMMITTER_NAME"\"," >> $CURRENT_META_JSON
                echo -e "\t\t\"commitDate\":\""$READER_COMMIT_DATE"\"," >> $CURRENT_META_JSON
                echo -e "\t\t\"email\":\""$READER_COMMITTER_EMAIL"\"," >> $CURRENT_META_JSON
                echo -e "\t\t\"commitURL\":\""$READER_COMMIT_URL"\"" >> $CURRENT_META_JSON
                echo -e "\t}" >> $CURRENT_META_JSON
                echo -e "}" >> $CURRENT_META_JSON
                sudo /bin/chown -Rf jenkins:www-data $NIGHTLY_ARTIFACTS_DIR/$1
                # Notify! Add next to sudoers:
                #jenkins ALL= NOPASSWD:/usr/bin/rrdtool,/home/jenkins/scripts/portgenerator-for-convert.sh,/home/jenkins/scripts/portgenerator-for-deploy.sh,/bin/chown -Rf jenkins\:www-data /home/jenkins/irls-reader-artifacts/*,/bin/chown -Rf jenkins\:www-data /home/jenkins/irls-reader-artifacts-nightly/*,/bin/bash
                /bin/chmod -Rf g+w $NIGHTLY_ARTIFACTS_DIR/$1
        }
        if [  -f $NIGHTLY_ARTIFACTS_DIR/$i/meta.json ]; then
                sudo /bin/chown -Rf jenkins:www-data $NIGHTLY_ARTIFACTS_DIR/$i
                /bin/chmod -Rf g+w $NIGHTLY_ARTIFACTS_DIR/$i
                cat /dev/null > $NIGHTLY_ARTIFACTS_DIR/$i/meta.json
                create_meta $i $TARGET_NAME
        else
                create_meta $i $TARGET_NAME
        fi
done

### Main loop
for i in "${TARGET[@]}"
do
        ### Temporary variables
        GIT_COMMIT_TARGET=$(echo "$READER_COMMIT_HASH"-"$i")
        CB_DIR="$NIGHTLY_BUILD/$GIT_COMMIT_TARGET" #code built directory
        CB_REMOTE_DIR="$NIGHTLY_REMOTE_BUILD/$GIT_COMMIT_TARGET" #remote (on mac-mini host) code built directory
        cd $WORKSPACE/$READER_REPO_NAME/client
	### Build client and server parts
        npm install grunt-compile-handlebars
        time node index.js --target=$i --targetPath=$WORKSPACE/$TARGETS_REPO_DIR_NAME --readerPath=$WORKSPACE/$READER_REPONAME
        time grunt production
        #cd $WORKSPACE/$READER_REPO_NAME/client
	#node compileHandlebars.js
        ### Build client and server parts
        #node index.js --target=$i --targetPath=$WORKSPACE/$TARGETS_REPO_DIR_NAME --readerPath=$WORKSPACE/$READER_REPO_NAME
        #grunt verify
        #grunt productionCompile
        ### Copy code of project to the directory $NIGHTLY_BUILD and removing outdated directories from the directory $NIGHTLY_BUILD (on the host dev01)
	rm -rf $CB_DIR
        mkdir -p $CB_DIR/client
        mkdir -p $CB_DIR/$TARGETS_REPO_DIR_NAME
        time rsync -rzv --delete --exclude ".git" --exclude "client" $WORKSPACE/$READER_REPO_NAME/ $CB_DIR/
        time rsync -rzv --delete $WORKSPACE/$READER_REPO_NAME/client/out/dist/ $CB_DIR/client/
        time rsync -rzv --delete --exclude ".git" $WORKSPACE/$TARGETS_REPO_DIR_NAME/ $CB_DIR/$TARGETS_REPO_DIR_NAME/
	### Copy meta.json to application directory
        for k in "${deploymentPackageId[@]}"; do if [[ $k == *$i ]]; then echo "copying meta.json for $k" && cp $NIGHTLY_ARTIFACTS_DIR/$k/meta.json $CB_DIR/client/; fi; done
        ### Create function for cleaning outdated directories from the directory of current code build
        function build_dir_clean (){
                # Numbers of directories in the $NIGHTLY_BUILD/
                NUM=$(ls -d $1/* | wc -l)
                echo NUM=$NUM
                # If number of directories is more than 10, then we will remove all directories except the five most recent catalogs
                if (( $NUM > 10 )); then
                        HEAD_NUM=$(($NUM-10))
                        echo HEAD_NUM=$HEAD_NUM
                        for k in $(ls -lahtrd $1/* | head -$HEAD_NUM | awk '{print $9}')
                        do
                                rm -rf $k
                        done
                fi
        }

        ### removing outdated directories from the directory $NIGHTLY_BUILD (on the host dev01)
        build_dir_clean $NIGHTLY_BUILD

	### copy project to mac-mini
        ssh jenkins@yuriys-mac-mini.isd.dp.ua "if [ ! -d $CB_REMOTE_DIR ]; then mkdir -p $CB_REMOTE_DIR; fi"
	time rsync -rzv --delete $CB_DIR/ jenkins@yuriys-mac-mini.isd.dp.ua:$CB_REMOTE_DIR/

	### copy project to dev02
        ssh jenkins@dev02.design.isd.dp.ua "if [ ! -d $CB_DIR ]; then mkdir -p $CB_DIR; fi"
	time rsync -rzv --delete $CB_DIR/ jenkins@dev02.design.isd.dp.ua:$CB_DIR/

        ### removing outdated directories from the directory $NIGHTLY_REMOTE_BUILD (on the host yuriys-mac-mini)
        typeset -f | ssh jenkins@yuriys-mac-mini.isd.dp.ua "$(typeset -f); build_dir_clean $NIGHTLY_REMOTE_BUILD"

        ### removing outdated directories from the directory $NIGHTLY_BUILD (on the host dev02)
        typeset -f | ssh jenkins@dev02.design.isd.dp.ua "$(typeset -f); build_dir_clean $NIGHTLY_BUILD"
done

rm -rf $WORKSPACE/$READER_REPO_NAME/client/out

###
### Variables for EnvInject plugin
###
cat /dev/null > $WORKSPACE/myenv
echo "NIGHTLY_BUILD=$NIGHTLY_BUILD" >> $WORKSPACE/myenv
echo "READER_BRANCH_NAME=$READER_BRANCH_NAME" >> $WORKSPACE/myenv
echo "READER_COMMIT_HASH=$READER_COMMIT_HASH" >> $WORKSPACE/myenv
echo deploymentPackageId=${deploymentPackageId[@]} >> $WORKSPACE/myenv
echo "TARGET=$(for i in ${TARGET[@]}; do printf "$i "; done)" >> $WORKSPACE/myenv
echo "NIGHTLY_MACMINI_EPUBS=$NIGHTLY_MACMINI_EPUBS" >> $WORKSPACE/myenv
echo "NIGHTLY_ARTIFACTS_DIR=$NIGHTLY_ARTIFACTS_DIR" >> $WORKSPACE/myenv
echo "NIGHTLY_REMOTE_BUILD=$NIGHTLY_REMOTE_BUILD" >> $WORKSPACE/myenv
echo "ENVIRONMENT=$ENVIRONMENT" >> $WORKSPACE/myenv
echo "NIGHTLY_EPUBS=$NIGHTLY_EPUBS" >> $WORKSPACE/myenv

