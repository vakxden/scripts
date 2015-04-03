#if [ -z $REPONAME ]; then
#        echo \[ERROR_REPO\] reponame not passed!
#        exit 1
#fi
#
#if [ -z $BRANCH ]; then
#        echo \[ERROR_BRANCH\] branch not passed!
#        exit 1
#fi
#
#function git_clone {
#        cd $WORKSPACE
#        git clone git@wpp.isd.dp.ua:irls/$REPONAME.git
#        }
#
#function git_checkout {
#        cd $WORKSPACE/$REPONAME
#        git reset --hard
#        git clean -fdx
#        git fetch --all
#        git checkout remotes/origin/$BRANCH
#        }
#
#
#if [ ! -d $WORKSPACE/$REPONAME ]; then
#        git_clone
#        git_checkout
#else
#        git_checkout
#fi
#
#cd $WORKSPACE/$REPONAME
time grunt --reponame=$REPONAME --branchname=$BRANCH
