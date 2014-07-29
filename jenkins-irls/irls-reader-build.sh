###
### Conditions for the base and non-base branches and facets for next initiate- and deploy-jobs
###
BRANCHNAME=$(echo $GIT_BRANCH | sed 's/origin\///g')
if [ -z $FACET ]; then
        if [ "$BRANCHNAME" = "develop" ] || [ "$BRANCHNAME" = "master" ]; then
                #FACET=(puddle farsi farsiref bahaiebooks audio audiobywords mediaoverlay lake ocean)
                FACET=(farsi3)
        elif [ "$BRANCHNAME" = "feature/target" ]; then
                FACET=(puddle)
        else
                #FACET=(puddle farsi audio)
                FACET=(puddle)
        fi
fi

###
### Variables
###
GIT_COMMIT_MESSAGE=$(git log -1 --pretty=format:%s $GIT_COMMIT)
GIT_COMMIT_DATE=$(git show -s --format=%ci)
GIT_COMMITTER_NAME=$(git show -s --format=%cn)
GIT_COMMITTER_EMAIL=$(git show -s --format=%ce)
CURRENT_BUILD=/home/jenkins/irls-reader-current-build
CURRENT_EPUBS=$HOME/irls-reader-current-epubs
CURRENT_REMOTE_BUILD=/Users/jenkins/irls-reader-current-build
ARTIFACTS_DIR=/home/jenkins/irls-reader-artifacts
META_SUM_ALL=$CURRENT_EPUBS/meta-all
GIT_COMMIT_RRM_SHORT=$(grep GIT_COMMIT_RRM $META_SUM_ALL | awk -F "=" '{print $2}' | cut -c1-7)
GIT_COMMIT_OC_SHORT=$(grep GIT_COMMIT_OC $META_SUM_ALL | awk -F "=" '{print $2}' | cut -c1-7)
GIT_COMMIT_SHORT=$(echo $GIT_COMMIT | cut -c1-7)

###
### Create variables for meta.json
###
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

###
### Generate deploymentPackageId
###
deploymentPackageId=()
for i in "${FACET[@]}"
do
        deploymentPackageId=("${deploymentPackageId[@]}" "$(echo "$GIT_COMMIT_SHORT$GIT_COMMIT_RRM_SHORT$GIT_COMMIT_OC_SHORT"_"$i")")
done

###
### Build client and server parts
###
### Clone targets-repo and running node with target option
if [ "$BRANCHNAME" = "feature/target" ]; then
        rm -rf targets
        git clone git@wpp.isd.dp.ua:irls/targets.git
        cd $WORKSPACE/client
        node index.js --target=$FACET\_FFA --targetPath=$WORKSPACE/targets
fi
grunt --no-color

###
### Copy code of project to the directory $CURRENT_BUILD and removing outdated directories from the directory $CURRENT_BUILD (on the host dev01)
###
if [ -d $CURRENT_BUILD/$GIT_COMMIT/client ]; then rm -rf $CURRENT_BUILD/$GIT_COMMIT/client/* ; else mkdir -p $CURRENT_BUILD/$GIT_COMMIT/client ; fi
cp -Rf $WORKSPACE/client/out/dist/* $CURRENT_BUILD/$GIT_COMMIT/client
if [ -d "$WORKSPACE/targets" ]; then cp -Rf $WORKSPACE/targets $CURRENT_BUILD/$GIT_COMMIT/ ; fi
if [ -d "$WORKSPACE/packager" ]; then cp -Rf $WORKSPACE/packager $CURRENT_BUILD/$GIT_COMMIT/ ; fi
if [ -d "$WORKSPACE/server" ]; then cp -Rf $WORKSPACE/server $CURRENT_BUILD/$GIT_COMMIT/ ; fi
if [ -d "$WORKSPACE/common" ]; then cp -Rf $WORKSPACE/common $CURRENT_BUILD/$GIT_COMMIT/ ; fi
if [ -d "$WORKSPACE/portal" ]; then cp -Rf $WORKSPACE/portal $CURRENT_BUILD/$GIT_COMMIT/ ; fi
# Numbers of directories in the $CURRENT_BUILD/
NUM=$(ls -d $CURRENT_BUILD/* | wc -l)
HEAD_NUM=$(($NUM-5))
# If number of directories is more than 5, then we will remove all directories except the five most recent catalogs
if [ "$NUM" > "5" ]; then
        for i in $(ls -lahtrd $CURRENT_BUILD/* | head -$HEAD_NUM | awk '{print $9}')
        do
                rm -rf $i
        done
fi

###
### Copy project to remote current build directory and removing outdated directories
###
### create archive
time tar cfz current_build-$GIT_COMMIT.tar.gz $CURRENT_BUILD/$GIT_COMMIT/packager $CURRENT_BUILD/$GIT_COMMIT/client $CURRENT_BUILD/$GIT_COMMIT/targets $CURRENT_BUILD/$GIT_COMMIT/portal
### copy to mac-mini
ssh jenkins@yuriys-mac-mini.isd.dp.ua "
       if [ ! -d $CURRENT_REMOTE_BUILD/$GIT_COMMIT ]; then mkdir -p $CURRENT_REMOTE_BUILD/$GIT_COMMIT ; else rm -rf $CURRENT_REMOTE_BUILD/$GIT_COMMIT/* ; fi
"
time scp current_build-$GIT_COMMIT.tar.gz jenkins@yuriys-mac-mini.isd.dp.ua:~
ssh jenkins@yuriys-mac-mini.isd.dp.ua "
       tar xfz current_build-$GIT_COMMIT.tar.gz -C $CURRENT_REMOTE_BUILD/$GIT_COMMIT/
       mv $CURRENT_REMOTE_BUILD/$GIT_COMMIT/$CURRENT_BUILD/$GIT_COMMIT/* $CURRENT_REMOTE_BUILD/$GIT_COMMIT/
       rm -rf $CURRENT_REMOTE_BUILD/$GIT_COMMIT/home
       rm -f current_build-$GIT_COMMIT.tar.gz
"
### copy to dev02
ssh jenkins@dev02.design.isd.dp.ua "
        if [ ! -d $CURRENT_BUILD/$GIT_COMMIT ]; then mkdir -p $CURRENT_BUILD/$GIT_COMMIT ; else rm -rf $CURRENT_BUILD/$GIT_COMMIT/* ; fi
"
scp current_build-$GIT_COMMIT.tar.gz  jenkins@dev02.design.isd.dp.ua:~
ssh jenkins@dev02.design.isd.dp.ua "
        tar xfz current_build-$GIT_COMMIT.tar.gz -C $CURRENT_BUILD/$GIT_COMMIT/
        mv $CURRENT_BUILD/$GIT_COMMIT/$CURRENT_BUILD/$GIT_COMMIT/* $CURRENT_BUILD/$GIT_COMMIT/
        rm -rf $CURRENT_BUILD/$GIT_COMMIT/home
        rm -f current_build-$GIT_COMMIT.tar.gz
"
### removing outdated directories from the directory $CURRENT_REMOTE_BUILD (on the host yuriys-mac-mini)
ssh jenkins@yuriys-mac-mini.isd.dp.ua "
        #numbers of directories in the $CURRENT_REMOTE_BUILD/
        NUM=\$(ls -d $CURRENT_REMOTE_BUILD/* | wc -l);
        HEAD_NUM=\$((NUM-5))
        # If number of directories is more than 5, then we will remove all directories except the five most recent catalogs
        if [ "\$NUM" > "5" ]; then
                for i in \$(ls -lahtrd $CURRENT_REMOTE_BUILD/* | head -\$HEAD_NUM | awk '{print \$9}')
                do
                        rm -rf \$i
                done
fi
"
### removing outdated directories from the directory $CURRENT_BUILD (on the host dev02)
ssh jenkins@dev02.design.isd.dp.ua "
        #numbers of directories in the $CURRENT_BUILD/
        NUM=\$(ls -d $CURRENT_BUILD/* | wc -l);
        HEAD_NUM=\$((NUM-5))
        # If number of directories is more than 5, then we will remove all directories except the five most recent catalogs
        if [ "\$NUM" > "5" ]; then
                for i in \$(ls -lahtrd $CURRENT_BUILD/* | head -\$HEAD_NUM | awk '{print \$9}')
                do
                        rm -rf \$i
                done
fi
"
### removing archive
rm -f $WORKSPACE/current_build-$GIT_COMMIT.tar.gz

###
### Create meta.json
###
for i in ${deploymentPackageId[@]}
do
	echo "numbers of element in array deploymentPackageId=${#deploymentPackageId[@]}"
        ### check exists directory $ARTIFACTS_DIR/$i
        if [ ! -d $ARTIFACTS_DIR/$i ]; then
        mkdir -p $ARTIFACTS_DIR/$i
        fi
        ### Determine facet name
        FACET_NAME=""
        FACET_NAME=$(echo $i | awk -F "_" '{print $2}')
	echo FACET_NAME=$FACET_NAME
        function create_meta {
		echo "Starting of function create_meta with variables $1 and $2"
		### $1 - it is deploymentPackageId
		### $2 - it is FACET_NAME
		CURRENT_META_JSON=""
		CURRENT_META_JSON=$ARTIFACTS_DIR/$1/meta.json
		echo CURRENT_META_JSON=$CURRENT_META_JSON
                echo -e "{" >> $CURRENT_META_JSON
                echo -e "\t\"buildID\":\""$1"\"," >> $CURRENT_META_JSON
                echo -e "\t\"facetName\":\""$2"\"," >> $CURRENT_META_JSON
                echo -e "\t\"buildURL\":\""$BUILD_URL"\"," >> $CURRENT_META_JSON
                echo -e "\t\"commitDate\":\""$GIT_COMMIT_DATE"\"," >> $CURRENT_META_JSON
                echo -e "\t\"rrm-processor\" : {" >> $CURRENT_META_JSON
                echo -e "\t\t\"commitID\":\""$GIT_COMMIT_RRM"\"," >> $CURRENT_META_JSON
                echo -e "\t\t\"commitMessage\":\""$GIT_COMMIT_MESSAGE_RRM"\"," >> $CURRENT_META_JSON
                echo -e "\t\t\"branchName\":\""$GIT_BRANCHNAME_RRM"\"," >> $CURRENT_META_JSON
                echo -e "\t\t\"commitAuthor\":\""$GIT_COMMITTER_NAME_RRM"\"," >> $CURRENT_META_JSON
                echo -e "\t\t\"commitDate\":\""$GIT_COMMIT_DATE_RRM"\"," >> $CURRENT_META_JSON
                echo -e "\t\t\"email\":\""$GIT_COMMITTER_EMAIL_RRM"\"," >> $CURRENT_META_JSON
                echo -e "\t\t\"commitURL\":\""$GIT_COMMIT_URL_RRM"\"" >> $CURRENT_META_JSON
                echo -e "\t}," >> $CURRENT_META_JSON
                echo -e "\t\"rrm-ocean\" : {" >> $CURRENT_META_JSON
                echo -e "\t\t\"commitID\":\""$GIT_COMMIT_OC"\"," >> $CURRENT_META_JSON
                echo -e "\t\t\"commitMessage\":\""$GIT_COMMIT_MESSAGE_OC"\"," >> $CURRENT_META_JSON
                echo -e "\t\t\"branchName\":\""$GIT_BRANCHNAME_OC"\"," >> $CURRENT_META_JSON
                echo -e "\t\t\"commitAuthor\":\""$GIT_COMMITTER_NAME_OC"\"," >> $CURRENT_META_JSON
                echo -e "\t\t\"commitDate\":\""$GIT_COMMIT_DATE_OC"\"," >> $CURRENT_META_JSON
                echo -e "\t\t\"email\":\""$GIT_COMMITTER_EMAIL_OC"\"," >> $CURRENT_META_JSON
                echo -e "\t\t\"commitURL\":\""$GIT_COMMIT_URL_OC"\"" >> $CURRENT_META_JSON
                echo -e "\t}," >> $CURRENT_META_JSON
                echo -e "\t\"reader\" : {" >> $CURRENT_META_JSON
                echo -e "\t\t\"commitID\":\""$GIT_COMMIT"\"," >> $CURRENT_META_JSON
                echo -e "\t\t\"commitMessage\":\""$GIT_COMMIT_MESSAGE"\"," >> $CURRENT_META_JSON
                echo -e "\t\t\"branchName\":\""$BRANCHNAME"\"," >> $CURRENT_META_JSON
                echo -e "\t\t\"commitAuthor\":\""$GIT_COMMIT_AUTHOR"\"," >> $CURRENT_META_JSON
                echo -e "\t\t\"commitDate\":\""$GIT_COMMIT_DATE"\"," >> $CURRENT_META_JSON
                echo -e "\t\t\"email\":\""$GIT_COMMITTER_EMAIL"\"," >> $CURRENT_META_JSON
                echo -e "\t\t\"commitURL\":\""$GIT_COMMIT_URL_READER"\"" >> $CURRENT_META_JSON
                echo -e "\t}" >> $CURRENT_META_JSON
                echo -e "}" >> $CURRENT_META_JSON
                sudo /bin/chown -Rf jenkins:www-data /home/jenkins/irls-reader-artifacts/$1
                /bin/chmod -Rf g+w /home/jenkins/irls-reader-artifacts/$1
        }
        if [  -f $ARTIFACTS_DIR/$i/meta.json ]; then
                cat /dev/null > $ARTIFACTS_DIR/$i/meta.json
                create_meta $i $FACET_NAME
        else
                create_meta $i $FACET_NAME
        fi
done

###
### Variables for EnvInject plugin
###
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
