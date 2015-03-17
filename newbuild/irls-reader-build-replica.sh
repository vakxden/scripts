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

### Variables of repositories
READER_REPONAME="product-replica"
TARGETS_REPONAME="targets-replica"
cd $READER_REPONAME
rm -rf node_modules && ln -s /opt/node/lib/node_modules node_modules
grunt checkout --targets_reponame=$TARGETS_REPONAME --workspace=$WORKSPACE

### Description
if [ -z "$STARTED_BY" ]; then
        echo \[WARN_MARK\] started by \<b\>3-irls-lib-processor-convert\</b\>\<br\> branch is \<b\>$BRANCHNAME\</b\>\<br\> target is \<b\>$TARGET\</b\>
else
        echo \[WARN_MARK\] started by \<b\>$STARTED_BY\</b\>\<br\> branch is \<b\>$BRANCHNAME\</b\>\<br\> target is \<b\>$TARGET\</b\>
fi
