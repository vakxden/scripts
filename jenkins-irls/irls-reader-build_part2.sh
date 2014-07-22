###
### Clone targets-repo and running node with target option
###
if [ "$BRANCHNAME" = "feature/target" ]; then
        rm -rf targets
        git clone git@wpp.isd.dp.ua:irls/targets.git
        cd $WORKSPACE/client
        node index.js --target=puddle_FFA
fi

###
### Build client and server parts
###
grunt --no-color

###
### Removing outdated directories from the directory $CURRENT_BUILD (on the host dev01)
###
# Numbers of directories in the $CURRENT_BUILD/
NUM=$(ls -d $CURRENT_BUILD/* | wc -l)
# If number of directories is more than 5, then we will remove all directories except the five most recent catalogs
if [ "\$NUM" > "5" ]; then
	echo "Number of directories is more than 5"
	for i in $(ls -lahtrd $CURRENT_BUILD/* | head -$(($num-5)) | awk '{print $9}')
	do
		rm -rf $i
	done
fi

### Copy
if [ ! -d $CURRENT_BUILD/$GIT_COMMIT/client ]
then
    mkdir -p $CURRENT_BUILD/$GIT_COMMIT/client
fi
cp -Rf $WORKSPACE/client/out/dist/* $CURRENT_BUILD/$GIT_COMMIT/client
cp -Rf $WORKSPACE/packager $CURRENT_BUILD/$GIT_COMMIT
cp -Rf $WORKSPACE/server $CURRENT_BUILD/$GIT_COMMIT
cp -Rf $WORKSPACE/common $CURRENT_BUILD/$GIT_COMMIT
if [ -d $WORKSPACE/portal ]; then
cp -Rf $WORKSPACE/portal $CURRENT_BUILD/$GIT_COMMIT
fi

###
### Copy project to remote current build directory
###

### create archive
time tar cfz current_build-$GIT_COMMIT.tar.gz $CURRENT_BUILD/$GIT_COMMIT/packager $CURRENT_BUILD/$GIT_COMMIT/client

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
### removing outdated directories from the directory $CURRENT_REMOTE_BUILD (on the host yuriys-mac-mini)
ssh jenkins@yuriys-mac-mini.isd.dp.ua "
	#numbers of directories in the $CURRENT_REMOTE_BUILD/
	NUM=\$(ls -d $CURRENT_REMOTE_BUILD/* | wc -l);
	HEAD_NUM=\$((NUM-5))
	# If number of directories is more than 5, then we will remove all directories except the five most recent catalogs
	if [ "\$NUM" > "5" ]; then
		echo "Number of directories is more than 5"
		for i in \$(ls -lahtrd $CURRENT_REMOTE_BUILD/* | head -\$HEAD_NUM | awk '{print \$9}')
		do
			rm -rf \$i
		done
fi
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
### removing outdated directories from the directory $CURRENT_BUILD (on the host dev02)
ssh jenkins@dev02.design.isd.dp.ua "
	#numbers of directories in the $CURRENT_BUILD/
	NUM=\$(ls -d $CURRENT_BUILD/* | wc -l);
	HEAD_NUM=\$((NUM-5))
	# If number of directories is more than 5, then we will remove all directories except the five most recent catalogs
	if [ "\$NUM" > "5" ]; then
		echo "Number of directories is more than 5"
		for i in \$(ls -lahtrd $CURRENT_BUILD/* | head -\$HEAD_NUM | awk '{print \$9}')
		do
			rm -rf \$i
		done
fi
"

###
### Create meta.json
###
ID=($(echo $deploymentPackageId))
for i in ${ID[@]}
do
        ###
        ### check exists directory $ARTIFACTS_DIR/$i
        ###
        if [ ! -d $ARTIFACTS_DIR/$i ]; then
        mkdir -p $ARTIFACTS_DIR/$i
        fi
        ###
        ### Determine facet name
        ###
        facetName=$(echo $i | awk -F "_" '{print $2}')
        function create_meta {
                echo -e "{" >> $ARTIFACTS_DIR/$i/meta.json
                echo -e "\t\"buildID\":\""$i"\"," >> $ARTIFACTS_DIR/$i/meta.json
                echo -e "\t\"facetName\":\""$facetName"\"," >> $ARTIFACTS_DIR/$i/meta.json
                echo -e "\t\"buildURL\":\""$BUILD_URL"\"," >> $ARTIFACTS_DIR/$i/meta.json
                echo -e "\t\"commitDate\":\""$GIT_COMMIT_DATE"\"," >> $ARTIFACTS_DIR/$i/meta.json
                echo -e "\t\"rrm-processor\" : {" >> $ARTIFACTS_DIR/$i/meta.json
                echo -e "\t\t\"commitID\":\""$GIT_COMMIT_RRM"\"," >> $ARTIFACTS_DIR/$i/meta.json
                echo -e "\t\t\"commitMessage\":\""$GIT_COMMIT_MESSAGE_RRM"\"," >> $ARTIFACTS_DIR/$i/meta.json
                echo -e "\t\t\"branchName\":\""$GIT_BRANCHNAME_RRM"\"," >> $ARTIFACTS_DIR/$i/meta.json
                echo -e "\t\t\"commitAuthor\":\""$GIT_COMMITTER_NAME_RRM"\"," >> $ARTIFACTS_DIR/$i/meta.json
                echo -e "\t\t\"commitDate\":\""$GIT_COMMIT_DATE_RRM"\"," >> $ARTIFACTS_DIR/$i/meta.json
                echo -e "\t\t\"email\":\""$GIT_COMMITTER_EMAIL_RRM"\"," >> $ARTIFACTS_DIR/$i/meta.json
                echo -e "\t\t\"commitURL\":\""$GIT_COMMIT_URL_RRM"\"" >> $ARTIFACTS_DIR/$i/meta.json
                echo -e "\t}," >> $ARTIFACTS_DIR/$i/meta.json
                echo -e "\t\"rrm-ocean\" : {" >> $ARTIFACTS_DIR/$i/meta.json
                echo -e "\t\t\"commitID\":\""$GIT_COMMIT_OC"\"," >> $ARTIFACTS_DIR/$i/meta.json
                echo -e "\t\t\"commitMessage\":\""$GIT_COMMIT_MESSAGE_OC"\"," >> $ARTIFACTS_DIR/$i/meta.json
                echo -e "\t\t\"branchName\":\""$GIT_BRANCHNAME_OC"\"," >> $ARTIFACTS_DIR/$i/meta.json
                echo -e "\t\t\"commitAuthor\":\""$GIT_COMMITTER_NAME_OC"\"," >> $ARTIFACTS_DIR/$i/meta.json
                echo -e "\t\t\"commitDate\":\""$GIT_COMMIT_DATE_OC"\"," >> $ARTIFACTS_DIR/$i/meta.json
                echo -e "\t\t\"email\":\""$GIT_COMMITTER_EMAIL_OC"\"," >> $ARTIFACTS_DIR/$i/meta.json
                echo -e "\t\t\"commitURL\":\""$GIT_COMMIT_URL_OC"\"" >> $ARTIFACTS_DIR/$i/meta.json
                echo -e "\t}," >> $ARTIFACTS_DIR/$i/meta.json
                echo -e "\t\"reader\" : {" >> $ARTIFACTS_DIR/$i/meta.json
                echo -e "\t\t\"commitID\":\""$GIT_COMMIT"\"," >> $ARTIFACTS_DIR/$i/meta.json
                echo -e "\t\t\"commitMessage\":\""$GIT_COMMIT_MESSAGE"\"," >> $ARTIFACTS_DIR/$i/meta.json
                echo -e "\t\t\"branchName\":\""$BRANCHNAME"\"," >> $ARTIFACTS_DIR/$i/meta.json
                echo -e "\t\t\"commitAuthor\":\""$GIT_COMMIT_AUTHOR"\"," >> $ARTIFACTS_DIR/$i/meta.json
                echo -e "\t\t\"commitDate\":\""$GIT_COMMIT_DATE"\"," >> $ARTIFACTS_DIR/$i/meta.json
                echo -e "\t\t\"email\":\""$GIT_COMMITTER_EMAIL"\"," >> $ARTIFACTS_DIR/$i/meta.json
                echo -e "\t\t\"commitURL\":\""$GIT_COMMIT_URL_READER"\"" >> $ARTIFACTS_DIR/$i/meta.json
                echo -e "\t}" >> $ARTIFACTS_DIR/$i/meta.json
                echo -e "}" >> $ARTIFACTS_DIR/$i/meta.json
                sudo /bin/chown -Rf jenkins:www-data /home/jenkins/irls-reader-artifacts/$i
                /bin/chmod -Rf g+w /home/jenkins/irls-reader-artifacts/$i
        }
        if [ ! -f $ARTIFACTS_DIR/$i/meta.json ]; then
                create_meta
        else
                cat /dev/null > $ARTIFACTS_DIR/$i/meta.json
                create_meta
        fi
done
