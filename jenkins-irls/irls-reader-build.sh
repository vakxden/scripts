### Checking of parameters
if [ -z $BRANCHNAME ]; then
        echo "[ERROR_PARAMETER] Parameter BRANCHNAME is empty!!"
        exit 1
fi
if [ -z $TARGET ]; then
        echo "[ERROR_PARAMETER] Parameter TARGET is empty!!"
        exit 1
fi
SPRINT="2.1"
TARGET=($(echo $TARGET))

### Variables of repositories
READER_REPONAME="product"
TARGETS_REPONAME="targets"

### Functions for git command
function git_clone {
        cd $WORKSPACE
        git clone git@wpp.isd.dp.ua:irls/$REPONAME.git
        }

function git_checkout {
        cd $WORKSPACE/$REPONAME
        git reset --hard
	git clean -fdx
	git fetch --all
        if [ "$REPONAME" == "product" ]; then
		git checkout origin/$BRANCHNAME
	elif  [ "$REPONAME" == "targets" ]; then
		git checkout origin/master
	fi
        }

### Clone product-repo and determine of GIT_COMMIT
REPONAME="$READER_REPONAME"
if [ ! -d $WORKSPACE/$REPONAME ]; then
        git_clone
        git_checkout
        GIT_COMMIT=$(git log -1  --pretty=format:%H)
        # if commit was to tests directory then this job is exit
        if git show --pretty="format:" --name-only $GIT_COMMIT | grep -o "^tests/"; then echo "[ERROR_COMMIT] This commit contains changes relating to the tests directory!" && exit 1; fi
else
        git_checkout
        GIT_COMMIT=$(git log -1  --pretty=format:%H)
        # if commit was to tests directory then this job is exit
        if git show --pretty="format:" --name-only $GIT_COMMIT | grep -o "^tests/"; then echo "[ERROR_COMMIT] This commit contains changes relating to the tests directory!" && exit 1; fi
fi

###
### Variables
###
CURRENT_BUILD=$HOME/irls-reader-current-build
if [ "$BRANCHNAME" != "master" ]; then
	CURRENT_EPUBS=$HOME/irls-reader-current-epubs/develop
else
	CURRENT_EPUBS=$HOME/irls-reader-current-epubs/$BRANCHNAME
fi
CURRENT_REMOTE_BUILD=/Users/jenkins/irls-reader-current-build
ARTIFACTS_DIR=$HOME/irls-reader-artifacts
#GIT_COMMIT_RRM_SHORT=$(grep GIT_COMMIT_RRM $META_SUM_ALL | awk -F "=" '{print $2}' | cut -c1-7)
#GIT_COMMIT_OC_SHORT=$(grep GIT_COMMIT_OC $META_SUM_ALL | awk -F "=" '{print $2}' | cut -c1-7)
cd $WORKSPACE/$READER_REPONAME
GIT_COMMIT_MESSAGE=$(git log -1 --pretty=format:%s $GIT_COMMIT)
GIT_COMMIT_DATE=$(git show -s --format=%ci)
GIT_COMMITTER_NAME=$(git show -s --format=%cn)
GIT_COMMITTER_EMAIL=$(git show -s --format=%ce)
GIT_COMMIT_SHORT=$(git log -1  --pretty=format:%h)


### Clone targets-repo and running node with target option
REPONAME="$TARGETS_REPONAME"
if [ ! -d $WORKSPACE/$REPONAME ]; then
        git_clone
        git_checkout
else
        git_checkout
fi

### Generate deploymentPackageId array
deploymentPackageId=()
for i in "${TARGET[@]}"
do
        #deploymentPackageId=("${deploymentPackageId[@]}" "$(echo "$GIT_COMMIT_SHORT$GIT_COMMIT_RRM_SHORT$GIT_COMMIT_OC_SHORT"_"$i")")
        deploymentPackageId=("${deploymentPackageId[@]}" "$(echo "$GIT_COMMIT_SHORT"_"$i")")
done

###
### Create meta.json
###
for i in ${deploymentPackageId[@]}
do
        echo "numbers of element in array deploymentPackageId=${#deploymentPackageId[@]}"
        ### check exists directory $ARTIFACTS_DIR/$i
        if [ ! -d $ARTIFACTS_DIR/$i ]; then
        mkdir -p $ARTIFACTS_DIR/$i
        fi
        ### Determine facet name
        TARGET_NAME=$(echo $i | sed 's@^.[0-9a-z]*_@@g')
	META_SUM_ALL=$CURRENT_EPUBS/$TARGET_NAME/meta-all
	###
	### Create variables for meta.json
	###
	# lib-processor
	LIB_PROCESSOR_REPO="lib-processor.git"
	GIT_COMMIT_RRM=$(grep GIT_COMMIT_RRM $META_SUM_ALL | awk -F "=" '{print $2}')
	GIT_COMMIT_MESSAGE_RRM=$( grep $LIB_PROCESSOR_REPO $META_SUM_ALL -A7 | grep GIT_COMMIT_MESSAGE | awk -F "=" '{print $2}')
	GIT_BRANCHNAME_RRM=$(grep $LIB_PROCESSOR_REPO $META_SUM_ALL -A7 | grep BRANCHNAME | awk -F "=" '{print $2}')
	GIT_COMMITTER_NAME_RRM=$(grep $LIB_PROCESSOR_REPO $META_SUM_ALL -A7 | grep GIT_COMMITTER_NAME | awk -F "=" '{print $2}')
	GIT_COMMIT_DATE_RRM=$(grep $LIB_PROCESSOR_REPO $META_SUM_ALL -A7 | grep GIT_COMMIT_DATE | awk -F "=" '{print $2}')
	GIT_COMMITTER_EMAIL_RRM=$(grep $LIB_PROCESSOR_REPO $META_SUM_ALL -A7 | grep GIT_COMMITTER_EMAIL | awk -F "=" '{print $2}')
	GIT_COMMIT_URL_RRM=$(grep $LIB_PROCESSOR_REPO $META_SUM_ALL -A7 | grep GIT_COMMIT_URL_RRM | awk -F "=" '{print $2}')
	# lib-sources
	LIB_SOURCES_REPO="lib-sources.git"
	GIT_COMMIT_OC=$(grep GIT_COMMIT_OC $META_SUM_ALL | awk -F "=" '{print $2}')
	GIT_COMMIT_MESSAGE_OC=$( grep $LIB_SOURCES_REPO $META_SUM_ALL -A7 | grep GIT_COMMIT_MESSAGE | awk -F "=" '{print $2}')
	GIT_BRANCHNAME_OC=$(grep $LIB_SOURCES_REPO $META_SUM_ALL -A7 | grep BRANCHNAME | awk -F "=" '{print $2}')
	GIT_COMMITTER_NAME_OC=$(grep $LIB_SOURCES_REPO $META_SUM_ALL -A7 | grep GIT_COMMIT_AUTHOR | awk -F "=" '{print $2}')
	GIT_COMMIT_DATE_OC=$(grep $LIB_SOURCES_REPO $META_SUM_ALL -A7 | grep GIT_COMMIT_DATE | awk -F "=" '{print $2}')
	GIT_COMMITTER_EMAIL_OC=$(grep $LIB_SOURCES_REPO $META_SUM_ALL -A7 | grep GIT_COMMITTER_EMAIL | awk -F "=" '{print $2}')
	GIT_COMMIT_URL_OC=$(grep $LIB_SOURCES_REPO $META_SUM_ALL -A7 | grep GIT_COMMIT_URL_OC | awk -F "=" '{print $2}')
	# product (old reader)
	cd $WORKSPACE/$READER_REPONAME
	GIT_COMMIT_MESSAGE=$(git log -1 --pretty=format:%s $GIT_COMMIT)
	GIT_COMMIT_DATE=$(git show -s --format=%ci)
	GIT_COMMIT_AUTHOR=$(git show -s --format=%an)
	GIT_COMMITTER_EMAIL=$(git show -s --format=%ce)
	GIT_COMMIT_URL_READER="http://wpp.isd.dp.ua/gitlab/$READER_REPONAME/commit/$GIT_COMMIT"
        function create_meta {
                echo "Starting of function create_meta with variables $1 and $2"
                ### $1 - it is deploymentPackageId
                ### $2 - it is TARGET_NAME
                CURRENT_META_JSON=""
                CURRENT_META_JSON=$ARTIFACTS_DIR/$1/meta.json
                echo CURRENT_META_JSON=$CURRENT_META_JSON
                echo -e "{" >> $CURRENT_META_JSON
                echo -e "\t\"buildID\":\""$1"\"," >> $CURRENT_META_JSON
                echo -e "\t\"targetName\":\""$2"\"," >> $CURRENT_META_JSON
                echo -e "\t\"buildURL\":\""$BUILD_URL"\"," >> $CURRENT_META_JSON
                echo -e "\t\"commitDate\":\""$GIT_COMMIT_DATE"\"," >> $CURRENT_META_JSON
                echo -e "\t\"rrm-processor\" : {" >> $CURRENT_META_JSON
                echo -e "\t\t\"commitID\":\""$GIT_COMMIT_RRM"\"," >> $CURRENT_META_JSON
                echo -e "\t\t\"commitMessage\":\""$GIT_COMMIT_MESSAGE_RRM"\"," >> $CURRENT_META_JSON
                echo -e "\t\t\"branchName\":\""$GIT_BRANCHNAME_RRM"\"," >> $CURRENT_META_JSON
                echo -e "\t\t\"commitAuthor\":\""$GIT_COMMITTER_NAME_RRM"\"," >> $CURRENT_META_JSON
                echo -e "\t\t\"commitDate\":\""$GIT_COMMIT_DATE_RRM"\"," >> $CURRENT_META_JSON
                echo -e "\t\t\"email\":\""$GIT_COMMITTER_EMAIL_RRM"\"," >> $CURRENT_META_JSON
                echo -e "\t\t\"commitURL\":\""$GIT_COMMIT_URL_RRM"\"" >> $CURRENT_META_JSON
                echo -e "\t}," >> $CURRENT_META_JSON
                echo -e "\t\"rrm-ocean\" : {" >> $CURRENT_META_JSON
                echo -e "\t\t\"commitID\":\""$GIT_COMMIT_OC"\"," >> $CURRENT_META_JSON
                echo -e "\t\t\"commitMessage\":\""$GIT_COMMIT_MESSAGE_OC"\"," >> $CURRENT_META_JSON
                echo -e "\t\t\"branchName\":\""$GIT_BRANCHNAME_OC"\"," >> $CURRENT_META_JSON
                echo -e "\t\t\"commitAuthor\":\""$GIT_COMMITTER_NAME_OC"\"," >> $CURRENT_META_JSON
                echo -e "\t\t\"commitDate\":\""$GIT_COMMIT_DATE_OC"\"," >> $CURRENT_META_JSON
                echo -e "\t\t\"email\":\""$GIT_COMMITTER_EMAIL_OC"\"," >> $CURRENT_META_JSON
                echo -e "\t\t\"commitURL\":\""$GIT_COMMIT_URL_OC"\"" >> $CURRENT_META_JSON
                echo -e "\t}," >> $CURRENT_META_JSON
                echo -e "\t\"reader\" : {" >> $CURRENT_META_JSON
                echo -e "\t\t\"commitID\":\""$GIT_COMMIT"\"," >> $CURRENT_META_JSON
                echo -e "\t\t\"commitMessage\":\""$( echo $GIT_COMMIT_MESSAGE | sed 's@"@@g')"\"," >> $CURRENT_META_JSON
                echo -e "\t\t\"branchName\":\""$BRANCHNAME"\"," >> $CURRENT_META_JSON
                echo -e "\t\t\"commitAuthor\":\""$GIT_COMMIT_AUTHOR"\"," >> $CURRENT_META_JSON
                echo -e "\t\t\"commitDate\":\""$GIT_COMMIT_DATE"\"," >> $CURRENT_META_JSON
                echo -e "\t\t\"email\":\""$GIT_COMMITTER_EMAIL"\"," >> $CURRENT_META_JSON
                echo -e "\t\t\"commitURL\":\""$GIT_COMMIT_URL_READER"\"" >> $CURRENT_META_JSON
                echo -e "\t}" >> $CURRENT_META_JSON
                echo -e "}" >> $CURRENT_META_JSON
                sudo /bin/chown -Rf jenkins:www-data /home/jenkins/irls-reader-artifacts/$1
                /bin/chmod -Rf g+w /home/jenkins/irls-reader-artifacts/$1
        }
        if [  -f $ARTIFACTS_DIR/$i/meta.json ]; then
                sudo /bin/chown -Rf jenkins:www-data /home/jenkins/irls-reader-artifacts/$i
                /bin/chmod -Rf g+w /home/jenkins/irls-reader-artifacts/$i
                cat /dev/null > $ARTIFACTS_DIR/$i/meta.json
                create_meta $i $TARGET_NAME
        else
                create_meta $i $TARGET_NAME
        fi
done

###
### Main loop
###
for i in "${TARGET[@]}"
do
        GIT_COMMIT_TARGET=$(echo "$GIT_COMMIT"-"$i")
        CB_DIR="$CURRENT_BUILD/$GIT_COMMIT_TARGET" #code built directory
        CB_REMOTE_DIR="$CURRENT_REMOTE_BUILD/$GIT_COMMIT_TARGET" #remote (on mac-mini host) code built directory
        cd $WORKSPACE/$READER_REPONAME/client
	# add sprint number line to build.info.json
        NUMBER_OF_SPRINT_LINE=$(grep "sprint" build.info.json -n | awk -F ":" '{print $1}')
        sed -i "$NUMBER_OF_SPRINT_LINE""s#\"sprint.*#\"sprint\":\"$SPRINT\",#g" build.info.json
        time node compileHandlebars.js
        ### Build client and server parts
        time node index.js --target=$i --targetPath=$WORKSPACE/$TARGETS_REPONAME --readerPath=$WORKSPACE/$READER_REPONAME
        time grunt verify
        time grunt productionCompile
        ### Copy code of project to the directory $CURRENT_BUILD and removing outdated directories from the directory $CURRENT_BUILD (on the host dev01)
        rm -rf $CB_DIR
        mkdir -p $CB_DIR/client $CB_DIR/targets
        time rsync -r --delete --exclude ".git" --exclude "client" $WORKSPACE/$READER_REPONAME/ $CB_DIR/
        time rsync -r --delete $WORKSPACE/$READER_REPONAME/client/out/dist/ $CB_DIR/client/
        time rsync -r --delete --exclude ".git" $WORKSPACE/$TARGETS_REPONAME/ $CB_DIR/targets/

        ### Copy meta.json to application directory
        for k in "${deploymentPackageId[@]}"; do if [[ $k == *$i ]]; then echo "copying meta.json for $k" && cp $ARTIFACTS_DIR/$k/meta.json $CB_DIR/client/; fi; done

        ### Create function for cleaning outdated directories from the directory of current code build
        function build_dir_clean (){
                # Numbers of directories in the $CURRENT_BUILD/
                NUM=$(ls -d $1/* | wc -l)
                echo NUM=$NUM
                # If number of directories is more than 20, then we will remove all directories except the 20 most recent catalogs
                if (( $NUM > 20 )); then
                        HEAD_NUM=$(($NUM-20))
                        echo HEAD_NUM=$HEAD_NUM
                        for k in $(ls -lahtrd $1/* | head -$HEAD_NUM | awk '{print $9}')
                        do
                                rm -rf $k
                        done
                fi
        }
        ### removing outdated directories from the directory $CURRENT_BUILD (on the host dev01)
        build_dir_clean $CURRENT_BUILD
        # remove archive from failed builds
        rm -f $WORKSPACE/current_build-*.tar.gz
        # rsync GIT_COMMIT_TARGET directory to other hosts
	if grep "platforms.*ios" $WORKSPACE/$TARGETS_REPONAME/$i/targetConfig.json; then
		ssh jenkins@yuriys-mac-mini.isd.dp.ua "
			if [ ! -d $CB_REMOTE_DIR ]; then mkdir -p $CB_REMOTE_DIR ; else rm -rf $CB_REMOTE_DIR/* ; fi
		"
		time rsync -rz --delete -e "ssh" $CB_DIR/ jenkins@yuriys-mac-mini.isd.dp.ua:$CB_REMOTE_DIR/
		### removing outdated directories from the directory $CURRENT_REMOTE_BUILD (on the host yuriys-mac-mini)
		typeset -f | ssh jenkins@yuriys-mac-mini.isd.dp.ua "$(typeset -f); build_dir_clean $CURRENT_REMOTE_BUILD"
	fi
	if grep "platforms.*android" $WORKSPACE/$TARGETS_REPONAME/$i/targetConfig.json; then
		ssh jenkins@dev02.design.isd.dp.ua "
			if [ ! -d $CB_DIR ]; then mkdir -p $CB_DIR ; else rm -rf $CB_DIR/* ; fi
		"
		time rsync -rz --delete -e "ssh" $CB_DIR/ jenkins@dev02.design.isd.dp.ua:$CB_DIR/
		### removing outdated directories from the directory $CURRENT_BUILD (on the host dev02)
		typeset -f | ssh jenkins@dev02.design.isd.dp.ua "$(typeset -f); build_dir_clean $CURRENT_BUILD"
	fi
done


###
### Variables for EnvInject plugin
###
cat /dev/null > $WORKSPACE/myenv
echo "BRANCHNAME=$BRANCHNAME" >> $WORKSPACE/myenv
echo "TARGET=$(for i in ${TARGET[@]}; do printf "$i "; done)" >> $WORKSPACE/myenv
echo "GIT_COMMIT=$GIT_COMMIT" >> $WORKSPACE/myenv
echo "GIT_COMMIT_MESSAGE=$GIT_COMMIT_MESSAGE" >> $WORKSPACE/myenv
echo "GIT_COMMIT_DATE=$GIT_COMMIT_DATE" >> $WORKSPACE/myenv
echo "GIT_COMMITTER_NAME=$GIT_COMMITTER_NAME" >> $WORKSPACE/myenv
echo "GIT_COMMITTER_EMAIL=$GIT_COMMITTER_EMAIL" >> $WORKSPACE/myenv
echo "CURRENT_BUILD=$CURRENT_BUILD" >> $WORKSPACE/myenv
echo "CURRENT_REMOTE_BUILD=$CURRENT_REMOTE_BUILD" >> $WORKSPACE/myenv
echo "ARTIFACTS_DIR=$ARTIFACTS_DIR" >> $WORKSPACE/myenv
echo deploymentPackageId=${deploymentPackageId[@]} >> $WORKSPACE/myenv
echo "GIT_COMMIT_RRM=$GIT_COMMIT_RRM" >> $WORKSPACE/myenv
echo "GIT_COMMIT_MESSAGE_RRM=$GIT_COMMIT_MESSAGE_RRM" >> $WORKSPACE/myenv
echo "GIT_BRANCHNAME_RRM=$GIT_BRANCHNAME_RRM" >> $WORKSPACE/myenv
echo "GIT_COMMITTER_NAME_RRM=$GIT_COMMITTER_NAME_RRM" >> $WORKSPACE/myenv
echo "GIT_COMMIT_DATE_RRM=$GIT_COMMIT_DATE_RRM" >> $WORKSPACE/myenv
echo "GIT_COMMITTER_EMAIL_RRM=$GIT_COMMITTER_EMAIL_RRM" >> $WORKSPACE/myenv
echo "GIT_COMMIT_URL_RRM=$GIT_COMMIT_URL_RRM" >> $WORKSPACE/myenv
echo "GIT_COMMIT_OC=$GIT_COMMIT_OC" >> $WORKSPACE/myenv
echo "GIT_COMMIT_MESSAGE_OC=$GIT_COMMIT_MESSAGE_OC" >> $WORKSPACE/myenv
echo "GIT_BRANCHNAME_OC=$GIT_BRANCHNAME_OC" >> $WORKSPACE/myenv
echo "GIT_COMMITTER_NAME_OC=$GIT_COMMITTER_NAME_OC" >> $WORKSPACE/myenv
echo "GIT_COMMIT_DATE_OC=$GIT_COMMIT_DATE_OC" >> $WORKSPACE/myenv
echo "GIT_COMMITTER_EMAIL_OC=$GIT_COMMITTER_EMAIL_OC" >> $WORKSPACE/myenv
echo "GIT_COMMIT_URL_OC=$GIT_COMMIT_URL_OC" >> $WORKSPACE/myenv
echo "GIT_COMMIT_MESSAGE=$GIT_COMMIT_MESSAGE" >> $WORKSPACE/myenv
echo "GIT_COMMIT_DATE=$GIT_COMMIT_DATE" >> $WORKSPACE/myenv
echo "GIT_COMMIT_AUTHOR=$GIT_COMMIT_AUTHOR" >> $WORKSPACE/myenv
echo "GIT_COMMITTER_EMAIL=$GIT_COMMITTER_EMAIL" >> $WORKSPACE/myenv
echo "GIT_COMMIT_URL_READER=$GIT_COMMIT_URL_READER" >> $WORKSPACE/myenv
### Description
if [ -z $STARTED_BY ]; then
	echo \[WARN_MARK\] started by \<b\>3-irls-lib-processor-convert\</b\>\<br\> branch is \<b\>$BRANCHNAME\</b\>\<br\> target is \<b\>$TARGET\</b\>
else
	echo \[WARN_MARK\] started by \<b\>$STARTED_BY\</b\>\<br\> branch is \<b\>$BRANCHNAME\</b\>\<br\> target is \<b\>$TARGET\</b\>
fi
