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
READER_REPONAME="product-replica"
TARGETS_REPONAME="targets-replica"

### Functions for git command
function git_clone () {
        cd $WORKSPACE
        git clone git@wpp.isd.dp.ua:irls/$1.git
        }
if [ ! -d $WORKSPACE/$READER_REPONAME ]; then git_clone $READER_REPONAME; fi
if [ ! -d $WORKSPACE/$TARGETS_REPONAME ]; then git_clone $TARGETS_REPONAME; fi
cd $WORKSPACE/$READER_REPONAME
grunt checkout --targets_reponame=$TARGETS_REPONAME --reader_reponame=$READER_REPONAME --reader_branchname=$BRANCHNAME --workspace=$WORKSPACE

### Description
if [ -z $STARTED_BY ]; then
        echo \[WARN_MARK\] started by \<b\>3-irls-lib-processor-convert\</b\>\<br\> branch is \<b\>$BRANCHNAME\</b\>\<br\> target is \<b\>$(for i in ${TARGET[@]}; do printf "$i "; done)\</b\>
else
        echo \[WARN_MARK\] started by \<b\>$STARTED_BY\</b\>\<br\> branch is \<b\>$BRANCHNAME\</b\>\<br\> target is \<b\>$(for i in ${TARGET[@]}; do printf "$i "; done)\</b\>
fi
