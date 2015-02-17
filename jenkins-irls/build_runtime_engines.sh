if [ -z $REPONAME ]; then
        echo \[ERROR_REPO\] reponame not passed!
        exit 1
fi

if [ -z $BRANCH ]; then
        echo \[ERROR_BRANCH\] branch not passed!
        exit 1
fi

function git_clone {
        cd $WORKSPACE
        git clone git@wpp.isd.dp.ua:irls/$REPONAME.git
        }

function git_checkout {
        cd $WORKSPACE/$REPONAME
        git reset --hard
        git clean -fdx
        git fetch --all
        git checkout remotes/origin/$BRANCH
        }


if [ ! -d $WORKSPACE/$REPONAME ]; then
        git_clone
        git_checkout
else
        git_checkout
fi

ssh jenkins@yuriys-mac-mini.isd.dp.ua "if [ ! -d ~/git/$REPONAME ]; then mkdir -p ~/git/$REPONAME ; fi"
time rsync -rz --delete -e "ssh" $WORKSPACE/$REPONAME/ jenkins@yuriys-mac-mini.isd.dp.ua:~/git/$REPONAME
ssh jenkins@dev02.design.isd.dp.ua "if [ ! -d ~/git/$REPONAME ]; then mkdir -p ~/git/$REPONAME ; fi"
time rsync -rz --delete -e "ssh" $WORKSPACE/$REPONAME/ jenkins@dev02.design.isd.dp.ua:~/git/$REPONAME
ssh jenkins@irls-autotests.design.isd.dp.ua "if [ ! -d ~/git/$REPONAME ]; then mkdir -p ~/git/$REPONAME ; fi"
time rsync -rz --delete -e "ssh" $WORKSPACE/$REPONAME/ jenkins@irls-autotests.design.isd.dp.ua:~/git/$REPONAME
# scp to users-mac-mini
ssh jenkins@users-Mac-mini.design.isd.dp.ua "if [ ! -d ~/git/$REPONAME ]; then mkdir -p ~/git/$REPONAME ; fi"
time rsync -rz --delete -e "ssh" $WORKSPACE/$REPONAME/ jenkins@users-Mac-mini.design.isd.dp.ua:~/git/$REPONAME
