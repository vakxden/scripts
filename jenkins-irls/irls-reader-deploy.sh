###
### This job sets default values facets for further deployment
###
ARTIFACTS_DIR=/home/jenkins/irls-reader-artifacts
TARGETS_REPO="git@wpp.isd.dp.ua:irls/targets.git"
TARGETS_REPO_DIR_NAME=$(echo $TARGETS_REPO | cut -d":" -f2 | cut -d"/" -f2 | sed s@.git@@g)

### Clone or "git pull" (if exist) targets-repo
if [ ! -d $WORKSPACE/$TARGETS_REPO_DIR_NAME ]; then
        cd $WORKSPACE && git clone $TARGETS_REPO
else
        cd $WORKSPACE/$TARGETS_REPO_DIR_NAME && git pull
fi
LIST_OF_ALL_TARGETS=($(cd $WORKSPACE/$TARGETS_REPO_DIR_NAME; ls -d ./* | sed s@\./@@g ));
if [ -z $TARGET ]; then TARGET=$LIST_OF_ALL_TARGETS; fi
deploymentPackageId=($(echo $ID))

for i in "${deploymentPackageId[@]}"
do
        BRANCHNAME=$(grep "reader.*:" $ARTIFACTS_DIR/$i/meta.json -A3 | grep "branchName" | awk -F "\"" '{print $4}')
        rm -f $WORKSPACE/myenv
        echo "BRANCHNAME=$BRANCHNAME" >> $WORKSPACE/myenv
done
if [ -z $BRANCHNAME ]; then
	printf "[ERROR_BRANCH] unable to determine the branch name \n"
	exit 1
fi
