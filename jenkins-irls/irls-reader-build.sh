BUILD_DATE=$(date "+%Y-%m-%d %H:%M")
### Checking of parameters
if [ -z $BRANCHNAME ]; then
        echo "[ERROR_PARAMETER] Parameter BRANCHNAME is empty!!"
        exit 1
fi
if [ -z $TARGET ]; then
        echo "[ERROR_PARAMETER] Parameter TARGET is empty!!"
        exit 1
fi
TARGET=($(echo $TARGET))

### Variables of repositories
READER_REPONAME="product"
TARGETS_REPONAME="$HOME/targets/master"

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
        #if git show --pretty="format:" --name-only $GIT_COMMIT | grep -o "^tests/"; then echo "[ERROR_COMMIT] This commit contains changes relating to the tests directory!" && exit 1; fi
else
        git_checkout
        GIT_COMMIT=$(git log -1  --pretty=format:%H)
        # if commit was to tests directory then this job is exit
        #if git show --pretty="format:" --name-only $GIT_COMMIT | grep -o "^tests/"; then echo "[ERROR_COMMIT] This commit contains changes relating to the tests directory!" && exit 1; fi
fi

###
### Variables
###
CURRENT_BUILD=$HOME/irls-reader-current-build
if [ "$BRANCHNAME" == "feature/conversion_result_caching" ]; then
        CURRENT_EPUBS=$HOME/irls-reader-current-epubs/feature/conversion_result_caching
elif [ "$BRANCHNAME" != "master" ]; then
        CURRENT_EPUBS=$HOME/irls-reader-current-epubs/develop
else
        CURRENT_EPUBS=$HOME/irls-reader-current-epubs/$BRANCHNAME
fi
CURRENT_REMOTE_BUILD=/Users/jenkins/irls-reader-current-build
ARTIFACTS_DIR=$HOME/irls-reader-artifacts
cd $WORKSPACE/$READER_REPONAME
GIT_COMMIT_MESSAGE=$(git log -1 --pretty=format:%s $GIT_COMMIT)
GIT_COMMIT_DATE=$(git show -s --format=%ci)
GIT_COMMITTER_NAME=$(git show -s --format=%cn)
GIT_COMMITTER_EMAIL=$(git show -s --format=%ce)
GIT_COMMIT_SHORT=$(git log -1  --pretty=format:%h)

### Generate deploymentPackageId array
deploymentPackageId=()
for i in "${TARGET[@]}"
do
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
        META_SUM_ALL=$CURRENT_EPUBS/$TARGET_NAME/meta-current-epubs-$TARGET_NAME.json

        ###
        ### Create variables for meta.json
        ###
        # product
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
                echo -e "\t\"buildNumber\":\""$BUILD_NUMBER"\"," >> $CURRENT_META_JSON
                echo -e "\t\"targetName\":\""$2"\"," >> $CURRENT_META_JSON
                echo -e "\t\"buildURL\":\""$BUILD_URL"\"," >> $CURRENT_META_JSON
                echo -e "\t\"commitDate\":\""$GIT_COMMIT_DATE"\"," >> $CURRENT_META_JSON
                grep "Processor" -A8 $META_SUM_ALL >> $CURRENT_META_JSON
                echo "," >> $CURRENT_META_JSON
                grep "Sources" -A8 $META_SUM_ALL >> $CURRENT_META_JSON
                echo "," >> $CURRENT_META_JSON
                echo -e "\t\"Product\" : {" >> $CURRENT_META_JSON
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
        if [ $BRANCHNAME == "feature/refactoring" ];
        then
                cd $WORKSPACE/$READER_REPONAME/build
        else
                cd $WORKSPACE/$READER_REPONAME/client
        fi
        ### Build client and server parts
        if [ $BRANCHNAME == "master" ];
        then
                time node compileHandlebars.js
                time node index.js --target=$i --targetPath=$TARGETS_REPONAME --readerPath=$WORKSPACE/$READER_REPONAME
                time grunt
        elif [ $BRANCHNAME == "feature/refactoring" ];
        then
                npm cache clear
                npm install grunt-compile-handlebars
                time node index.target.js --target=$i --targetPath=$TARGETS_REPONAME --readerPath=$WORKSPACE/$READER_REPONAME
                time grunt

        else
                npm cache clear
                npm install grunt-compile-handlebars
                time node index.js --target=$i --targetPath=$TARGETS_REPONAME --readerPath=$WORKSPACE/$READER_REPONAME
                time grunt production
                cd $WORKSPACE/$READER_REPONAME/server
                time grunt
                cd $WORKSPACE/$READER_REPONAME/client
        fi
        rm -rf $CB_DIR
        if [ $BRANCHNAME == "feature/refactoring" ];
        then
                mkdir -p $CB_DIR/build $CB_DIR/targets
                time rsync -r --delete --exclude ".git" $WORKSPACE/$READER_REPONAME/ $CB_DIR/
                time rsync -r --delete $WORKSPACE/$READER_REPONAME/build/out/ $CB_DIR/build/
                time rsync -r --delete --exclude ".git" $TARGETS_REPONAME/ $CB_DIR/targets/
        else
                mkdir -p $CB_DIR/client $CB_DIR/targets
                time rsync -r --delete --exclude ".git" --exclude "client" $WORKSPACE/$READER_REPONAME/ $CB_DIR/
                time rsync -r --delete $WORKSPACE/$READER_REPONAME/client/out/dist/ $CB_DIR/client/
                time rsync -r --delete --exclude ".git" $TARGETS_REPONAME/ $CB_DIR/targets/
        fi

        ### Copy meta.json to application directory
	if [ $BRANCHNAME == "feature/refactoring" ];
        then
		for k in "${deploymentPackageId[@]}"; do if [[ $k == *$i ]]; then echo "copying meta.json for $k" && cp $ARTIFACTS_DIR/$k/meta.json $CB_DIR/build/; fi; done
	else
		for k in "${deploymentPackageId[@]}"; do if [[ $k == *$i ]]; then echo "copying meta.json for $k" && cp $ARTIFACTS_DIR/$k/meta.json $CB_DIR/client/; fi; done
	fi

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
        if grep "platforms.*ios" $TARGETS_REPONAME/$i/targetConfig.json; then
                ssh jenkins@yuriys-mac-mini.isd.dp.ua "
                        if [ ! -d $CB_REMOTE_DIR ]; then mkdir -p $CB_REMOTE_DIR ; else rm -rf $CB_REMOTE_DIR/* ; fi
                "
                time rsync -rz --delete -e "ssh" $CB_DIR/ jenkins@yuriys-mac-mini.isd.dp.ua:$CB_REMOTE_DIR/
                ### removing outdated directories from the directory $CURRENT_REMOTE_BUILD (on the host yuriys-mac-mini)
                typeset -f | ssh jenkins@yuriys-mac-mini.isd.dp.ua "$(typeset -f); build_dir_clean $CURRENT_REMOTE_BUILD"
        fi
        if grep "platforms.*android" $TARGETS_REPONAME/$i/targetConfig.json; then
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
echo "BUILD_DATE=$BUILD_DATE" >> $WORKSPACE/myenv
echo "BUILD_NUMBER=$BUILD_NUMBER" >> $WORKSPACE/myenv
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
        echo \[WARN_MARK\] started by \<b\>lib-convert\</b\>\<br\> branch is \<b\>$BRANCHNAME\</b\>\<br\> target is \<b\>$(for i in ${TARGET[@]}; do printf "$i "; done)\</b\>
else
        echo \[WARN_MARK\] started by \<b\>$STARTED_BY\</b\>\<br\> branch is \<b\>$BRANCHNAME\</b\>\<br\> target is \<b\>$(for i in ${TARGET[@]}; do printf "$i "; done)\</b\>
fi
