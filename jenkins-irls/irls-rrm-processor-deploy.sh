### Variables
PROJECTNAME=$(basename $GIT_URL | sed 's/\.git//g')
CURRENT_RRM=/home/jenkins/irls-rrm-processor-deploy
GIT_REPO=$(echo $GIT_URL | awk -F ":" '{print $2}' | sed 's/\.git//g')
GIT_COMMIT_URL_RRM="http://wpp.isd.dp.ua/gitlab/$GIT_REPO/commit/$GIT_COMMIT_RRM"

### Variables for EnvInject plugin
rm -f myenv
echo "PROJECTNAME=$PROJECTNAME" >> myenv
echo "CURRENT_RRM=$CURRENT_RRM" >> myenv
echo "$GIT_URL=$GIT_URL" >> myenv
echo "BRANCHNAME=$BRANCHNAME" >> myenv
echo "GIT_COMMIT_RRM=$GIT_COMMIT_RRM" >> myenv
echo "GIT_COMMIT_MESSAGE=$( echo $GIT_COMMIT_MESSAGE | sed 's@"@@g')" >> myenv
echo "GIT_COMMIT_DATE=$GIT_COMMIT_DATE" >> myenv
echo "GIT_COMMIT_URL_RRM=$GIT_COMMIT_URL_RRM" >> myenv
echo "GIT_COMMITTER_NAME=$GIT_COMMITTER_NAME" >> myenv
echo "GIT_COMMITTER_EMAIL=$GIT_COMMITTER_EMAIL" >> myenv
