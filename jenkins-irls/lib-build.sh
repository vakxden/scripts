        # check variables
        if [ -z $PROCESSOR_BRANCHNAME ]; then
                echo processor branchname value not received
                exit 1
        fi
        if [ -z $SOURCES_BRANCHNAME ]; then
                echo sources branchname value not received
                exit 1
        fi

        # clean inject environment variables file
        ENV_FILE="$WORKSPACE/computed_environment_variables"
        cat /dev/null > $ENV_FILE

        ###
        ### Processor section
        ###
        PROCESSOR_CURRENT_CODE_PATH=$HOME/irls-$PROCESSOR_REPONAME-deploy
        echo "PROCESSOR_CURRENT_CODE_PATH=$PROCESSOR_CURRENT_CODE_PATH" >> $ENV_FILE
        PROCESSOR_META=$PROCESSOR_REPONAME-meta.json
        echo "PROCESSOR_META=$PROCESSOR_META" >> $ENV_FILE

        # check variables
        if [ -z $PROCESSOR_HASHCOMMIT ]; then
                PROCESSOR_HASHCOMMIT=$(curl -s http://wpp.isd.dp.ua/irls-reader-artifacts/$PROCESSOR_REPONAME-status.json | grep '"branchName":"'$PROCESSOR_BRANCHNAME'"' | awk -F '"|"' '{print $8}')
                echo "PROCESSOR_HASHCOMMIT=$PROCESSOR_HASHCOMMIT" >> $ENV_FILE
        fi

        # check directory exists
        if [ ! -d $PROCESSOR_CURRENT_CODE_PATH/$PROCESSOR_HASHCOMMIT ]; then
                mkdir -p $PROCESSOR_CURRENT_CODE_PATH/$PROCESSOR_HASHCOMMIT
        fi
        if [ "$(ls -A $PROCESSOR_CURRENT_CODE_PATH/$PROCESSOR_HASHCOMMIT)" ]; then
                echo "directory $PROCESSOR_CURRENT_CODE_PATH/$PROCESSOR_HASHCOMMIT is not empty"
        else
                # clean before
                rm -rf $WORKSPACE/$PROCESSOR_REPONAME

                # shallow clone
                git init $WORKSPACE/$PROCESSOR_REPONAME
                cd  $WORKSPACE/$PROCESSOR_REPONAME
                git remote add origin git@wpp.isd.dp.ua:irls/$PROCESSOR_REPONAME.git
                time git fetch origin $PROCESSOR_BRANCHNAME:refs/remotes/origin/$PROCESSOR_BRANCHNAME
                time git checkout -f $PROCESSOR_HASHCOMMIT

                # determine variables for meta.json file
                PROCESSOR_COMMIT_URL="http://wpp.isd.dp.ua/gitlab/irls/$PROCESSOR_REPONAME/commit/$PROCESSOR_HASHCOMMIT"
                PROCESSOR_COMMIT_MESSAGE=$(git show origin/$PROCESSOR_BRANCHNAME -s --format=%s | sed 's@"@@g')
                PROCESSOR_COMMIT_DATE=$(git show origin/$PROCESSOR_BRANCHNAME -s --format=%ci)
                PROCESSOR_COMMIT_AUTHOR=$(git show origin/$PROCESSOR_BRANCHNAME -s --format=%cn)
                PROCESSOR_COMMIT_AUTHOR_EMAIL=$(git show -s origin/$PROCESSOR_BRANCHNAME --format=%ce)

                # verify (jshint, jscs), create meta.json file, and rsync to current code directory, clean old directory
                time grunt --git_commit=$PROCESSOR_HASHCOMMIT \
                --commit_message="$PROCESSOR_COMMIT_MESSAGE" \
                --branchname="$PROCESSOR_BRANCHNAME" \
                --commit_author="$PROCESSOR_COMMIT_AUTHOR" \
                --commit_date="$PROCESSOR_COMMIT_DATE" \
                --email="$PROCESSOR_COMMIT_AUTHOR_EMAIL" \
                --commit_url="$PROCESSOR_COMMIT_URL" \
                --meta_json_file=$PROCESSOR_META \
                --current_code_path=$PROCESSOR_CURRENT_CODE_PATH
        fi


        ###
        ### Sources section
        ###
        SOURCES_CURRENT_CODE_PATH=$HOME/irls-$SOURCES_REPONAME-deploy
        echo "SOURCES_CURRENT_CODE_PATH=$SOURCES_CURRENT_CODE_PATH" >> $ENV_FILE
        SOURCES_META=$SOURCES_REPONAME-meta.json
        echo "SOURCES_META=$SOURCES_META" >> $ENV_FILE

        # check variables
        if [ -z $SOURCES_HASHCOMMIT ]; then
                SOURCES_HASHCOMMIT=$(curl -s http://wpp.isd.dp.ua/irls-reader-artifacts/$SOURCES_REPONAME-status.json | grep '"branchName":"'$SOURCES_BRANCHNAME'"' | awk -F '"|"' '{print $8}')
                echo "SOURCES_HASHCOMMIT=$SOURCES_HASHCOMMIT" >> $ENV_FILE
        fi

        # check directory exists
        if [ ! -d $SOURCES_CURRENT_CODE_PATH/$SOURCES_HASHCOMMIT ]; then
                mkdir -p $SOURCES_CURRENT_CODE_PATH/$SOURCES_HASHCOMMIT
        fi
        if [ "$(ls -A $SOURCES_CURRENT_CODE_PATH/$SOURCES_HASHCOMMIT)" ]; then
                echo "directory $SOURCES_CURRENT_CODE_PATH/$SOURCES_HASHCOMMIT is not empty"
        else
                # clean before
                rm -rf $WORKSPACE/$SOURCES_REPONAME

                # shallow clone
                git init $WORKSPACE/$SOURCES_REPONAME
                cd  $WORKSPACE/$SOURCES_REPONAME
                git remote add origin git@wpp.isd.dp.ua:irls/$SOURCES_REPONAME.git
                time git fetch origin $SOURCES_BRANCHNAME:refs/remotes/origin/$SOURCES_BRANCHNAME
                time git checkout -f $SOURCES_HASHCOMMIT
				if [ $PROCESSOR_BRANCHNAME = "audio" ]; then 
					git annex sync origin
					git annex get .
				fi
				
                # determine variables for meta.json file
                SOURCES_COMMIT_URL="http://wpp.isd.dp.ua/gitlab/irls/$SOURCES_REPONAME/commit/$SOURCES_HASHCOMMIT"
                SOURCES_COMMIT_MESSAGE=$(git show origin/$SOURCES_BRANCHNAME -s --format=%s | sed 's@"@@g')
                SOURCES_COMMIT_DATE=$(git show origin/$SOURCES_BRANCHNAME -s --format=%ci)
                SOURCES_COMMIT_AUTHOR=$(git show origin/$SOURCES_BRANCHNAME -s --format=%cn)
                SOURCES_COMMIT_AUTHOR_EMAIL=$(git show -s origin/$SOURCES_BRANCHNAME --format=%ce)

                # create meta.json file and rsync to current code directory, clean old directory
                time grunt --git_commit=$SOURCES_HASHCOMMIT \
                --commit_message="$SOURCES_COMMIT_MESSAGE" \
                --branchname="$SOURCES_BRANCHNAME" \
                --commit_author="$SOURCES_COMMIT_AUTHOR" \
                --commit_date="$SOURCES_COMMIT_DATE" \
                --email="$SOURCES_COMMIT_AUTHOR_EMAIL" \
                --commit_url="$SOURCES_COMMIT_URL" \
                --meta_json_file=$SOURCES_META \
                --current_code_path=$SOURCES_CURRENT_CODE_PATH
        fi
