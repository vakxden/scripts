### Variables
RRM_PROCESSOR_REPO_NAME="rrm-processor"
RRM_PROCESSOR_BRANCH_NAME="master"
RRM_OCEAN_REPO_NAME="rrm-ocean"
RRM_OCEAN_BRANCH_NAME="master"
READER_REPO_NAME="reader"
READER_BRANCH_NAME="develop"
TARGETS_REPO_NAME="targets"
TARGETS_BRANCH_NAME="master"
FACET=(puddle farsi farsi3 bahaiebooks audio audiobywords mediaoverlay lake ocean)
NIGHTLY_EPUBS="$HOME/irls-reader-nightly-epubs"
NIGHTLY_MACMINI_EPUBS="/Users/jenkins/irls-reader-nigtly-epubs/"
NIGHTLY_ARTIFACTS_DIR="/home/jenkins/irls-reader-artifacts-nightly"
NIGHTLY_BUILD="/home/jenkins/irls-reader-nightly-build"
NIGHTLY_REMOTE_BUILD="/Users/jenkins/irls-reader-nightly-build"

### Check exists directory
if [ ! -d "$NIGHTLY_EPUBS" ]; then mkdir $NIGHTLY_EPUBS; fi
if [ ! -d "$NIGHTLY_ARTIFACTS_DIR" ]; then mkdir -p $NIGHTLY_ARTIFACTS_DIR; fi

### git operations
if [ ! -d "$WORKSPACE/$RRM_PROCESSOR_REPO_NAME" ]; then
	cd $WORKSPACE && git clone git@wpp.isd.dp.ua:irls/"$RRM_PROCESSOR_REPO_NAME".git && cd $WORKSPACE/$RRM_PROCESSOR_REPO_NAME && git checkout $RRM_PROCESSOR_BRANCH_NAME
else
	cd $WORKSPACE/$RRM_PROCESSOR_REPO_NAME && git pull && git checkout $RRM_PROCESSOR_BRANCH_NAME
fi

if [ ! -d "$WORKSPACE/$RRM_OCEAN_REPO_NAME" ]; then
	cd $WORKSPACE && git clone git@wpp.isd.dp.ua:irls/"$RRM_OCEAN_REPO_NAME".git && cd $WORKSPACE/$RRM_OCEAN_REPO_NAME  && git checkout $RRM_OCEAN_BRANCH_NAME
else
	cd $WORKSPACE/$RRM_OCEAN_REPO_NAME && git pull && git checkout $RRM_OCEAN_BRANCH_NAME
fi

if [ ! -d "$WORKSPACE/$READER_REPO_NAME" ]; then
	cd $WORKSPACE && git clone git@wpp.isd.dp.ua:irls/"$READER_REPO_NAME".git && cd $WORKSPACE/$READER_REPO_NAME && git checkout $READER_BRANCH_NAME
else
	cd $WORKSPACE/$READER_REPO_NAME && git pull && git checkout $READER_BRANCH_NAME
fi
        
if [ ! -d "$WORKSPACE/$TARGETS_REPO_NAME" ]; then
	cd $WORKSPACE && git clone git@wpp.isd.dp.ua:irls/"$TARGETS_REPO_NAME".git && cd $WORKSPACE/$TARGETS_REPO_NAME && git checkout $TARGETS_BRANCH_NAME
else
	cd $WORKSPACE/$TARGETS_REPO_NAME && git pull && git checkout $TARGETS_BRANCH_NAME
fi

### Convert
#for i in ${FACET[@]}
#do
#	rm -rf $NIGHTLY_EPUBS/$i
#	mkdir -p $NIGHTLY_EPUBS/$i
#	cd $WORKSPACE/$RRM_PROCESSOR_REPO_NAME/src
#	time node main.js $WORKSPACE/$RRM_OCEAN_REPO_NAME $NIGHTLY_EPUBS/$i $i
#	time node --max-old-space-size=7000 $WORKSPACE/$RRM_PROCESSOR_REPO_NAME/src/createJSON.js $NIGHTLY_EPUBS/$i/
#done

### Copy current epubs to jenkins nodes
#for i in "${FACET[@]}"
#do
#        # create tar.xz archive
#	NIGHTLY_ARCH_NAME="nightly-$i.tar.xz"
#        time tar cfJ $NIGHTLY_ARCH_NAME $NIGHTLY_EPUBS/$i --exclude="_oldjson"
#        ### Copy current epubs to mac-mini
#        if [ "$i" = "ocean" ]; then
#                printf "epubs for facet named 'ocean' will not be copying to mac-mini \n"
#        else
#                ssh jenkins@yuriys-mac-mini.isd.dp.ua "
#                        if [ ! -d $NIGHTLY_MACMINI_EPUBS/$i ]; then mkdir -p $NIGHTLY_MACMINI_EPUBS/$i; fi
#                        rm -rf $NIGHTLY_MACMINI_EPUBS/$i/*
#                "
#                time scp $NIGHTLY_ARCH_NAME jenkins@yuriys-mac-mini.isd.dp.ua:~
#                ssh jenkins@yuriys-mac-mini.isd.dp.ua "
#                        tar xfJ $NIGHTLY_ARCH_NAME -C $NIGHTLY_MACMINI_EPUBS/$i/
#                        mv $NIGHTLY_MACMINI_EPUBS/$i$NIGHTLY_EPUBS/$i/* $NIGHTLY_MACMINI_EPUBS/$i/ && rm -rf $NIGHTLY_MACMINI_EPUBS/$i/home
#                        rm -f $NIGHTLY_ARCH_NAME
#                "
#        fi
#        ### Copy current epubs to dev02.design.isd.dp.ua
#        if [ "$i" = "ocean" ]; then
#                printf "epubs for facet named 'ocean' will not be copying to dev02 \n"
#        else
#		ssh jenkins@dev02.design.isd.dp.ua "
#			if [ ! -d $NIGHTLY_EPUBS/$i ]; then mkdir -p $NIGHTLY_EPUBS/$i; fi
#			rm -rf $NIGHTLY_EPUBS/$i/*
#		"
#		time scp $NIGHTLY_ARCH_NAME jenkins@dev02.design.isd.dp.ua:~
#		ssh jenkins@dev02.design.isd.dp.ua "
#			tar xfJ $NIGHTLY_ARCH_NAME -C $NIGHTLY_EPUBS/$i/
#			mv $NIGHTLY_EPUBS/$i$NIGHTLY_EPUBS/$i/* $NIGHTLY_EPUBS/$i/ && rm -rf $NIGHTLY_EPUBS/$i/home
#			rm -f $NIGHTLY_ARCH_NAME
#		"
#	fi
#        # remove tar.xz archive
#        rm -f $NIGHTLY_ARCH_NAME
#done
### Create variables for meta.json
# rrm-processor
cd $WORKSPACE/$RRM_PROCESSOR_REPO_NAME
RRM_PROCESSOR_COMMIT_MESSAGE=$(git log -1 --pretty=format:"%s")
RRM_PROCESSOR_COMMIT_DATE=$(git log -1 --pretty=format:"%ci")
RRM_PROCESSOR_COMMITTER_NAME=$(git log -1 --pretty=format:"%cn")
RRM_PROCESSOR_COMMITTER_EMAIL=$(git log -1 --pretty=format:"%ce")
RRM_PROCESSOR_COMMIT_HASH=$(git log -1 --pretty=format:"%H")
RRM_PROCESSOR_SHORT_COMMIT_HASH=$(git log -1 --pretty=format:"%h")
RRM_PROCESSOR_COMMIT_URL="http://wpp.isd.dp.ua/gitlab/irls/$RRM_PROCESSOR_REPO_NAME/commit/$RRM_PROCESSOR_COMMIT_HASH"
# rrm-ocean
cd $WORKSPACE/$RRM_OCEAN_REPO_NAME
RRM_OCEAN_COMMIT_MESSAGE=$(git log -1 --pretty=format:"%s")
RRM_OCEAN_COMMIT_DATE=$(git log -1 --pretty=format:"%ci")
RRM_OCEAN_COMMITTER_NAME=$(git log -1 --pretty=format:"%cn")
RRM_OCEAN_COMMITTER_EMAIL=$(git log -1 --pretty=format:"%ce")
RRM_OCEAN_COMMIT_HASH=$(git log -1 --pretty=format:"%H")
RRM_OCEAN_SHORT_COMMIT_HASH=$(git log -1 --pretty=format:"%h")
RRM_OCEAN_COMMIT_URL="http://wpp.isd.dp.ua/gitlab/irls/$RRM_OCEAN_REPO_NAME/commit/$RRM_OCEAN_COMMIT_HASH"
# reader
cd $WORKSPACE/$READER_REPO_NAME
READER_COMMIT_MESSAGE=$(git log -1 --pretty=format:"%s")
READER_COMMIT_DATE=$(git log -1 --pretty=format:"%ci")
READER_COMMITTER_NAME=$(git log -1 --pretty=format:"%cn")
READER_COMMITTER_EMAIL=$(git log -1 --pretty=format:"%ce")
READER_COMMIT_HASH=$(git log -1 --pretty=format:"%H")
READER_SHORT_COMMIT_HASH=$(git log -1 --pretty=format:"%h")
READER_COMMIT_URL="http://wpp.isd.dp.ua/gitlab/irls/$READER_REPO_NAME/commit/$READER_COMMIT_HASH"

### Array declaration
deploymentPackageId=()

### Main loop
for i in "${FACET[@]}"
do
        ### Generate deploymentPackageId
        deploymentPackageId=("${deploymentPackageId[@]}" "$(echo "$READER_SHORT_COMMIT_HASH$RRM_PROCESSOR_SHORT_COMMIT_HASH$RRM_OCEAN_SHORT_COMMIT_HASH"_"$i")")
        ### Temporary variables
        TARG=$(echo "$i"_FFA)
        GIT_COMMIT_TARGET=$(echo "$READER_COMMIT_HASH"-"$TARG")
        CB_DIR="$NIGHTLY_BUILD/$GIT_COMMIT_TARGET" #code built directory
        CB_REMOTE_DIR="$NIGHTLY_REMOTE_BUILD/$GIT_COMMIT_TARGET" #remote (on mac-mini host) code built directory
        cd $WORKSPACE/$READER_REPO_NAME/client
        ### Build client and server parts
        node index.js --target=$TARG --targetPath=$WORKSPACE/$TARGETS_REPO_NAME
        grunt --no-color
        ### Copy code of project to the directory $NIGHTLY_BUILD and removing outdated directories from the directory $NIGHTLY_BUILD (on the host dev01)
        if [ -d $CB_DIR/client ]; then rm -rf $CB_DIR/client/* ; else mkdir -p $CB_DIR/client ; fi
        cp -Rf $WORKSPACE/client/out/dist/* $CB_DIR/client
        if [ -d "$WORKSPACE/targets" ]; then cp -Rf $WORKSPACE/targets $CB_DIR/ ; fi
        if [ -d "$WORKSPACE/packager" ]; then cp -Rf $WORKSPACE/packager $CB_DIR/ ; fi
        if [ -d "$WORKSPACE/server" ]; then cp -Rf $WORKSPACE/server $CB_DIR/ ; fi
        if [ -d "$WORKSPACE/common" ]; then cp -Rf $WORKSPACE/common $CB_DIR/ ; fi
        if [ -d "$WORKSPACE/portal" ]; then cp -Rf $WORKSPACE/portal $CB_DIR/ ; fi
        ### Create function for cleaning outdated directories from the directory of current code build
        function build_dir_clean (){
                # Numbers of directories in the $NIGHTLY_BUILD/
                NUM=$(ls -d $1/* | wc -l)
                echo NUM=$NUM
                HEAD_NUM=$(($NUM-20))
                echo HEAD_NUM=$HEAD_NUM
                # If number of directories is more than 20, then we will remove all directories except the five most recent catalogs
                if [ "$NUM" > "20" ]; then
                        for k in $(ls -lahtrd $1/* | head -$HEAD_NUM | awk '{print $9}')
                        do
                                rm -rf $k
                        done
                fi
        }
        ### removing outdated directories from the directory $NIGHTLY_BUILD (on the host dev01)
        build_dir_clean $NIGHTLY_BUILD
        ### create archive
        time tar cfz $WORKSPACE/current_build-$GIT_COMMIT_TARGET.tar.gz $CB_DIR/packager $CB_DIR/client $CB_DIR/targets $CB_DIR/portal
        ### copy project to mac-mini
        ssh jenkins@yuriys-mac-mini.isd.dp.ua "
               if [ ! -d $CB_REMOTE_DIR ]; then mkdir -p $CB_REMOTE_DIR ; else rm -rf $CB_REMOTE_DIR/* ; fi
        "
        time scp $WORKSPACE/current_build-$GIT_COMMIT_TARGET.tar.gz jenkins@yuriys-mac-mini.isd.dp.ua:~
        ssh jenkins@yuriys-mac-mini.isd.dp.ua "
               tar xfz current_build-$GIT_COMMIT_TARGET.tar.gz -C $CB_REMOTE_DIR/
               mv $CB_REMOTE_DIR/$CB_DIR/* $CB_REMOTE_DIR/
               rm -rf $CB_REMOTE_DIR/home
               rm -f current_build-$GIT_COMMIT_TARGET.tar.gz
        "
        ### copy project to dev02
        ssh jenkins@dev02.design.isd.dp.ua "
                if [ ! -d $CB_DIR ]; then mkdir -p $CB_DIR ; else rm -rf $CB_DIR/* ; fi
        "
        scp $WORKSPACE/current_build-$GIT_COMMIT_TARGET.tar.gz  jenkins@dev02.design.isd.dp.ua:~
        ssh jenkins@dev02.design.isd.dp.ua "
                tar xfz current_build-$GIT_COMMIT_TARGET.tar.gz -C $CB_DIR/
                mv $CB_DIR/$CB_DIR/* $CB_DIR/
                rm -rf $CB_DIR/home
                rm -f current_build-$GIT_COMMIT_TARGET.tar.gz
        "
        ### removing outdated directories from the directory $NIGHTLY_REMOTE_BUILD (on the host yuriys-mac-mini)
        typeset -f | ssh jenkins@yuriys-mac-mini.isd.dp.ua "$(typeset -f); build_dir_clean $NIGHTLY_REMOTE_BUILD"
        ### removing outdated directories from the directory $NIGHTLY_BUILD (on the host dev02)
        typeset -f | ssh jenkins@dev02.design.isd.dp.ua "$(typeset -f); build_dir_clean $NIGHTLY_BUILD"
        ### removing archive
        rm -f $WORKSPACE/current_build-$GIT_COMMIT_TARGET.tar.gz
done

rm -rf $WORKSPACE/reader/client/out

### Create meta.json
for i in ${deploymentPackageId[@]}
do
        echo "numbers of element in array deploymentPackageId=${#deploymentPackageId[@]}"
        ### check exists directory $NIGHTLY_ARTIFACTS_DIR/$i
        if [ ! -d $NIGHTLY_ARTIFACTS_DIR/$i ]; then mkdir -p $NIGHTLY_ARTIFACTS_DIR/$i; fi
        ### Determine facet name
        FACET_NAME=""
        FACET_NAME=$(echo $i | awk -F "_" '{print $2}')
        echo FACET_NAME=$FACET_NAME
        function create_meta {
                echo "Starting of function create_meta with variables $1 and $2"
                ### $1 - it is deploymentPackageId
                ### $2 - it is FACET_NAME
                CURRENT_META_JSON=""
                CURRENT_META_JSON=$NIGHTLY_ARTIFACTS_DIR/$1/meta.json
                echo CURRENT_META_JSON=$CURRENT_META_JSON
                echo -e "{" >> $CURRENT_META_JSON
                echo -e "\t\"buildID\":\""$1"\"," >> $CURRENT_META_JSON
                echo -e "\t\"facetName\":\""$2"\"," >> $CURRENT_META_JSON
                echo -e "\t\"buildURL\":\""$BUILD_URL"\"," >> $CURRENT_META_JSON
                echo -e "\t\"commitDate\":\""$READER_COMMIT_DATE"\"," >> $CURRENT_META_JSON
                echo -e "\t\"rrm-processor\" : {" >> $CURRENT_META_JSON
                echo -e "\t\t\"commitID\":\""$RRM_PROCESSOR_COMMIT_HASH"\"," >> $CURRENT_META_JSON
                echo -e "\t\t\"commitMessage\":\""$RRM_PROCESSOR_COMMIT_MESSAGE"\"," >> $CURRENT_META_JSON
                echo -e "\t\t\"branchName\":\""$RRM_PROCESSOR_BRANCH_NAME"\"," >> $CURRENT_META_JSON
                echo -e "\t\t\"commitAuthor\":\""$RRM_PROCESSOR_COMMITTER_NAME"\"," >> $CURRENT_META_JSON
                echo -e "\t\t\"commitDate\":\""$RRM_PROCESSOR_COMMIT_DATE"\"," >> $CURRENT_META_JSON
                echo -e "\t\t\"email\":\""$RRM_PROCESSOR_COMMITTER_EMAIL"\"," >> $CURRENT_META_JSON
                echo -e "\t\t\"commitURL\":\""$RRM_PROCESSOR_COMMIT_URL"\"" >> $CURRENT_META_JSON
                echo -e "\t}," >> $CURRENT_META_JSON
                echo -e "\t\"rrm-ocean\" : {" >> $CURRENT_META_JSON
                echo -e "\t\t\"commitID\":\""$RRM_OCEAN_COMMIT_HASH"\"," >> $CURRENT_META_JSON
                echo -e "\t\t\"commitMessage\":\""$RRM_OCEAN_COMMIT_MESSAGE"\"," >> $CURRENT_META_JSON
                echo -e "\t\t\"branchName\":\""$RRM_OCEAN_BRANCH_NAME"\"," >> $CURRENT_META_JSON
                echo -e "\t\t\"commitAuthor\":\""$RRM_OCEAN_COMMITTER_NAME"\"," >> $CURRENT_META_JSON
                echo -e "\t\t\"commitDate\":\""$RRM_OCEAN_COMMIT_DATE"\"," >> $CURRENT_META_JSON
                echo -e "\t\t\"email\":\""$RRM_OCEAN_COMMITTER_EMAIL"\"," >> $CURRENT_META_JSON
                echo -e "\t\t\"commitURL\":\""$RRM_OCEAN_COMMIT_URL"\"" >> $CURRENT_META_JSON
                echo -e "\t}," >> $CURRENT_META_JSON
                echo -e "\t\"reader\" : {" >> $CURRENT_META_JSON
                echo -e "\t\t\"commitID\":\""$READER_COMMIT_HASH"\"," >> $CURRENT_META_JSON
                echo -e "\t\t\"commitMessage\":\""$READER_COMMIT_MESSAGE"\"," >> $CURRENT_META_JSON
                echo -e "\t\t\"branchName\":\""$READER_BRANCH_NAME"\"," >> $CURRENT_META_JSON
                echo -e "\t\t\"commitAuthor\":\""$READER_COMMITTER_NAME"\"," >> $CURRENT_META_JSON
                echo -e "\t\t\"commitDate\":\""$READER_COMMIT_DATE"\"," >> $CURRENT_META_JSON
                echo -e "\t\t\"email\":\""$READER_COMMITTER_EMAIL"\"," >> $CURRENT_META_JSON
                echo -e "\t\t\"commitURL\":\""$READER_COMMIT_URL"\"" >> $CURRENT_META_JSON
                echo -e "\t}" >> $CURRENT_META_JSON
                echo -e "}" >> $CURRENT_META_JSON
                sudo /bin/chown -Rf jenkins:www-data /home/jenkins/irls-reader-artifacts/$1
                /bin/chmod -Rf g+w /home/jenkins/irls-reader-artifacts/$1
        }
        if [  -f $NIGHTLY_ARTIFACTS_DIR/$i/meta.json ]; then
                sudo /bin/chown -Rf jenkins:www-data /home/jenkins/irls-reader-artifacts/$i
                /bin/chmod -Rf g+w /home/jenkins/irls-reader-artifacts/$i
                cat /dev/null > $NIGHTLY_ARTIFACTS_DIR/$i/meta.json
                create_meta $i $FACET_NAME
        else
                create_meta $i $FACET_NAME
        fi
done