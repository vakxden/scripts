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
else
        git_checkout
        GIT_COMMIT=$(git log -1  --pretty=format:%H)
fi

###
### Variables
###
CURRENT_BUILD=$HOME/irls-reader-current-build
CURRENT_EPUBS=$HOME/irls-reader-current-epubs
ARTIFACTS_DIR=$HOME/irls-reader-artifacts
cd $WORKSPACE/$READER_REPONAME
GIT_COMMIT_MESSAGE=$(git log -1 --pretty=format:%s $GIT_COMMIT)
GIT_COMMIT_DATE=$(git show -s --format=%ci)
GIT_COMMITTER_NAME=$(git show -s --format=%cn)
GIT_COMMITTER_EMAIL=$(git show -s --format=%ce)
GIT_COMMIT_SHORT=$(git log -1  --pretty=format:%h)
#frome node
export NODE_HOME=/opt/node
export PATH=$PATH:$NODE_HOME/bin
# from phantom
export NODE_PATH=/opt/node/lib/node_modules/

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
        deploymentPackageId=("${deploymentPackageId[@]}" "$(echo "$GIT_COMMIT_SHORT$GIT_COMMIT_RRM_SHORT$GIT_COMMIT_OC_SHORT"_"$i")")
done

###
### Main loop
###
for i in "${TARGET[@]}"
do
        GIT_COMMIT_TARGET=$(echo "$GIT_COMMIT"-"$i")
        CB_DIR="$CURRENT_BUILD/$GIT_COMMIT_TARGET" #code built directory
        cd $WORKSPACE/$READER_REPONAME/client
        ### Build client and server parts
        npm install grunt-compile-handlebars
        time node index.js --target=$i --targetPath=$WORKSPACE/$TARGETS_REPONAME --readerPath=$WORKSPACE/$READER_REPONAME
        time grunt production
        #cd $WORKSPACE/$READER_REPONAME/client
        #time node compileHandlebars.js
        ### Build client and server parts
        #time node index.js --target=$i --targetPath=$WORKSPACE/$TARGETS_REPONAME --readerPath=$WORKSPACE/$READER_REPONAME
        #time grunt verify
        #time grunt productionCompile
        ### Copy code of project to the directory $CURRENT_BUILD and removing outdated directories from the directory $CURRENT_BUILD (on the host dev01)
        rm -rf $CB_DIR
        mkdir -p $CB_DIR/client $CB_DIR/targets
        time rsync -r --delete --exclude ".git" --exclude "client" $WORKSPACE/$READER_REPONAME/ $CB_DIR/
        time rsync -r --delete $WORKSPACE/$READER_REPONAME/client/out/dist/ $CB_DIR/client/
        time rsync -r --delete --exclude ".git" $WORKSPACE/$TARGETS_REPONAME/ $CB_DIR/targets/
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
done


###
### Variables for EnvInject plugin
###
cat /dev/null > $WORKSPACE/myenv
echo "BRANCHNAME=$BRANCHNAME" >> $WORKSPACE/myenv
echo "TARGET=$(for i in ${TARGET[@]}; do printf "$i "; done)" >> $WORKSPACE/myenv
echo "GIT_COMMIT=$GIT_COMMIT" >> $WORKSPACE/myenv
echo "CURRENT_BUILD=$CURRENT_BUILD" >> $WORKSPACE/myenv
echo "ARTIFACTS_DIR=$ARTIFACTS_DIR" >> $WORKSPACE/myenv
echo deploymentPackageId=${deploymentPackageId[@]} >> $WORKSPACE/myenv
