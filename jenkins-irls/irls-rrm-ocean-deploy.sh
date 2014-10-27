### Variables
BRANCHNAME=$(basename $GIT_BRANCH)
GIT_COMMIT_MESSAGE=$(git log -1 --pretty=format:%s $GIT_COMMIT)
GIT_COMMIT_DATE=$(git show -s --format=%ci)
GIT_COMMIT_AUTHOR=$(git show -s --format=%an)
GIT_COMMITTER_EMAIL=$(git show -s --format=%ce)
CURRENT_TEXTS=$HOME/irls-reader-current-texts
META=$CURRENT_TEXTS/meta-ocean-deploy
GIT_REPO=$(echo $GIT_URL | awk -F ":" '{print $2}' | sed 's/\.git//g')
GIT_COMMIT_URL_OC="http://wpp.isd.dp.ua/gitlab/$GIT_REPO/commit/$GIT_COMMIT"

### Variables for EnvInject plugin
rm -f myenv
echo "GIT_URL=$GIT_URL" >> myenv
echo "BRANCHNAME=$BRANCHNAME" >> myenv
echo "GIT_COMMIT_OC=$GIT_COMMIT" >> myenv
echo "GIT_COMMIT_MESSAGE=$( echo $GIT_COMMIT_MESSAGE | sed 's@"@@g')" >> myenv
echo "GIT_COMMIT_DATE=$GIT_COMMIT_DATE" >> myenv
echo "GIT_COMMIT_AUTHOR=$GIT_COMMIT_AUTHOR" >> myenv
echo "GIT_COMMITTER_EMAIL=$GIT_COMMITTER_EMAIL" >> myenv
echo "CURRENT_TEXTS=$CURRENT_TEXTS" >> myenv
echo "GIT_COMMIT_URL_OC=$GIT_COMMIT_URL_OC" >> myenv
echo "META=$META" >> myenv
