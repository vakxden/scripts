SOURCES_REPONAME="lib-sources"
GIT_URL="http://wpp.isd.dp.ua/gitlab/irls/$SOURCES_REPONAME"
CURRENT_TEXTS=$HOME/irls-reader-current-texts

### Functions for git command
function git_clone {
        cd $WORKSPACE
        git clone git@wpp.isd.dp.ua:irls/$SOURCES_REPONAME
        }

function git_checkout {
        cd $WORKSPACE/$SOURCES_REPONAME
        git reset --hard
        git clean -fdx
        git fetch --all
        git checkout origin/$BRANCHNAME
        GIT_COMMIT=$(git log -1  --pretty=format:%H)
        GIT_COMMIT_MESSAGE=$(git log -1 --pretty=format:%s $GIT_COMMIT | sed 's@"@@g')
        GIT_COMMIT_DATE=$(git show -s --format=%ci)
        GIT_COMMITTER_NAME=$(git show -s --format=%cn)
        GIT_COMMITTER_EMAIL=$(git show -s --format=%ce)
        }

function sources_dir_clean (){
                # Numbers of directories in the $CURRENT_TEXTS/
                NUM=$(ls -d $1/* | wc -l)
                echo NUM=$NUM
                # If number of directories is more than 5, then we will remove all directories except the 5 most recent catalogs
                if (( $NUM > 5 )); then
                        HEAD_NUM=$(($NUM-5))
                        echo HEAD_NUM=$HEAD_NUM
                        for k in $(ls -lahtrd $1/* | head -$HEAD_NUM | awk '{print $9}')
                        do
                                rm -rf $k
                        done
                fi
        }


### Clone or checkout
if [ ! -d $WORKSPACE/$SOURCES_REPONAME ]; then
        git_clone
        git_checkout
else
        git_checkout
fi

### Move code to current directory
cd $WORKSPACE
if [ ! -d $CURRENT_TEXTS/$GIT_COMMIT ]; then mkdir -p $CURRENT_TEXTS/$GIT_COMMIT; fi
time rsync -r --delete --exclude ".git" $WORKSPACE/$SOURCES_REPONAME/ $CURRENT_TEXTS/$GIT_COMMIT/

### Clean of old directories
sources_dir_clean $CURRENT_TEXTS

### Create meta
META=$CURRENT_TEXTS/$GIT_COMMIT/meta-ocean-deploy
rm -f $META
touch $META
echo "GIT_URL='$GIT_URL'.git" >> $META
echo "BRANCHNAME=$BRANCHNAME" >> $META
echo "GIT_COMMIT_OC=$GIT_COMMIT" >> $META
echo "GIT_COMMIT_MESSAGE=$GIT_COMMIT_MESSAGE" >> $META
echo "GIT_COMMIT_DATE=$GIT_COMMIT_DATE" >> $META
echo "GIT_COMMITTER_NAME=$GIT_COMMITTER_NAME" >> $META
echo "GIT_COMMITTER_EMAIL=$GIT_COMMITTER_EMAIL" >> $META
echo "GIT_COMMIT_URL_OC=$GIT_URL/commit/$GIT_COMMIT" >> $META

### myenv
cat /dev/null > $WORKSPACE/myenv
echo "GIT_COMMIT=$GIT_COMMIT" >> $WORKSPACE/myenv
