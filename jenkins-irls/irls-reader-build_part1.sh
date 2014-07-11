### Variables
BRANCHNAME=$(echo $GIT_BRANCH | sed 's/origin\///g')
if [ -z $FACET ]; then
	if [ "$BRANCHNAME" = "develop" ] || [ "$BRANCHNAME" = "master" ]; then
		FACET=(puddle bahaiebooks farsi farsiref audio audiobywords mediaoverlay lake ocean)
	elif [ "$BRANCHNAME" = "feature/target" ]; then
		FACET=(puddle)
	else
		FACET=(puddle bahaiebooks audio mediaoverlay lake)
	fi
fi
GIT_COMMIT_MESSAGE=$(git log -1 --pretty=format:%s $GIT_COMMIT)
GIT_COMMIT_DATE=$(git show -s --format=%ci)
GIT_COMMITTER_NAME=$(git show -s --format=%cn)
GIT_COMMITTER_EMAIL=$(git show -s --format=%ce)
CURRENT_BUILD=/home/jenkins/irls-reader-current-build
CURRENT_EPUBS=$HOME/irls-reader-current-epubs
CURRENT_REMOTE_BUILD=/Users/jenkins/irls-reader-current-build

###
### Removing outdated directories from a directory $CURRENT_BUILD
###
#numbers of directories in $CURRENT_BUILD/
num=$(ls -d $CURRENT_BUILD/* | wc -l)
# if num>5 -> remove all directories except the five most recent catalogs
if (($num>5)); then
	echo "numbers of dir>5"
	for i in $(ls -lahtrd $CURRENT_BUILD/* | head -$(($num-5)) | awk '{print $9}')
	do
		rm -rf $i
	done
fi

# generate deploymentPackageId
META_SUM_ALL=$CURRENT_EPUBS/meta-all
GIT_COMMIT_RRM_SHORT=$(grep GIT_COMMIT_RRM $META_SUM_ALL | awk -F "=" '{print $2}' | cut -c1-7)
GIT_COMMIT_OC_SHORT=$(grep GIT_COMMIT_OC $META_SUM_ALL | awk -F "=" '{print $2}' | cut -c1-7)
GIT_COMMIT_SHORT=$(echo $GIT_COMMIT | cut -c1-7)
printf "facet=$FACET \n"
deploymentPackageId=()
for i in "${FACET[@]}"
do
	deploymentPackageId=("${deploymentPackageId[@]}" "$(echo "$GIT_COMMIT_SHORT$GIT_COMMIT_RRM_SHORT$GIT_COMMIT_OC_SHORT"_"$i")")
done

### generate meta.json
ARTIFACTS_DIR=/home/jenkins/irls-reader-artifacts

## variables for meta.json
# rrm-processor
GIT_COMMIT_RRM=$(grep GIT_COMMIT_RRM $META_SUM_ALL | awk -F "=" '{print $2}')
GIT_COMMIT_MESSAGE_RRM=$( grep "rrm-processor.git" $META_SUM_ALL -A7 | grep GIT_COMMIT_MESSAGE | awk -F "=" '{print $2}')
GIT_BRANCHNAME_RRM=$(grep "rrm-processor.git" /home/jenkins/irls-reader-current-epubs/meta-all -A7 | grep BRANCHNAME | awk -F "=" '{print $2}')
GIT_COMMITTER_NAME_RRM=$(grep "rrm-processor.git" /home/jenkins/irls-reader-current-epubs/meta-all -A7 | grep GIT_COMMITTER_NAME | awk -F "=" '{print $2}')
GIT_COMMIT_DATE_RRM=$(grep "rrm-processor.git" /home/jenkins/irls-reader-current-epubs/meta-all -A7 | grep GIT_COMMIT_DATE | awk -F "=" '{print $2}')
GIT_COMMITTER_EMAIL_RRM=$(grep "rrm-processor.git" /home/jenkins/irls-reader-current-epubs/meta-all -A7 | grep GIT_COMMITTER_EMAIL | awk -F "=" '{print $2}')
GIT_COMMIT_URL_RRM=$(grep "rrm-processor.git" /home/jenkins/irls-reader-current-epubs/meta-all -A7 | grep GIT_COMMIT_URL_RRM | awk -F "=" '{print $2}')
# rrm-ocean
GIT_COMMIT_OC=$(grep GIT_COMMIT_OC $META_SUM_ALL | awk -F "=" '{print $2}')
GIT_COMMIT_MESSAGE_OC=$( grep "rrm-ocean.git" $META_SUM_ALL -A7 | grep GIT_COMMIT_MESSAGE | awk -F "=" '{print $2}')
GIT_BRANCHNAME_OC=$(grep "rrm-ocean.git" /home/jenkins/irls-reader-current-epubs/meta-all -A7 | grep BRANCHNAME | awk -F "=" '{print $2}')
GIT_COMMITTER_NAME_OC=$(grep "rrm-ocean.git" /home/jenkins/irls-reader-current-epubs/meta-all -A7 | grep GIT_COMMIT_AUTHOR | awk -F "=" '{print $2}')
GIT_COMMIT_DATE_OC=$(grep "rrm-ocean.git" /home/jenkins/irls-reader-current-epubs/meta-all -A7 | grep GIT_COMMIT_DATE | awk -F "=" '{print $2}')
GIT_COMMITTER_EMAIL_OC=$(grep "rrm-ocean.git" /home/jenkins/irls-reader-current-epubs/meta-all -A7 | grep GIT_COMMITTER_EMAIL | awk -F "=" '{print $2}')
GIT_COMMIT_URL_OC=$(grep "rrm-ocean.git" /home/jenkins/irls-reader-current-epubs/meta-all -A7 | grep GIT_COMMIT_URL_OC | awk -F "=" '{print $2}')
# reader
GIT_COMMIT_MESSAGE=$(git log -1 --pretty=format:%s $GIT_COMMIT)
GIT_COMMIT_DATE=$(git show -s --format=%ci)
GIT_COMMIT_AUTHOR=$(git show -s --format=%an)
GIT_COMMITTER_EMAIL=$(git show -s --format=%ce)
GIT_REPO=$(echo $GIT_URL | awk -F ":" '{print $2}' | sed 's/\.git//g')
GIT_COMMIT_URL_READER="http://wpp.isd.dp.ua/gitlab/$GIT_REPO/commit/$GIT_COMMIT"

### Variables for EnvInject plugin
cat /dev/null > $WORKSPACE/myenv
echo "$GIT_URL=$GIT_URL" >> $WORKSPACE/myenv
echo "BRANCHNAME=$BRANCHNAME" >> $WORKSPACE/myenv
echo "FACET=$(for i in ${FACET[@]}; do printf "$i "; done)" >> $WORKSPACE/myenv
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
