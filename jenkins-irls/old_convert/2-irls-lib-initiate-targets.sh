PROCESSOR_REPONAME="lib-processor"
SOURCES_REPONAME="lib-sources"

STATUS_FILE="/home/jenkins/irls-reader-artifacts/status.json"
if [ ! -f $STATUS_FILE ]; then
        touch $STATUS_FILE
        echo -e '{
        "lib-processor" : {
                "branchName":"develop",
                "commitID":"8fff0140ad5a49cf5519d5d0ea0aa0109212b36b"
        },
        "lib-sources" : {
                "branchName":"master",
                "commitID":"c126f76c5464db9bdbfac13dbb07f99c159abb13"
        }
}' >> $STATUS_FILE
fi

function update_status_file {
        # $1 = received commit
        # $2 = reponame
        # $3 = $PROCESSOR_BRANCH or $SOURCES_BRANCH
        CURRENT=$(grep $2 $STATUS_FILE -A9 | grep "branchName.*$3" -A1 | grep commit | awk -F '"|"' '{print $4}')
        if [ "$1" == "$CURRENT" ]; then
                echo received commit from $2 is equal to current commit from $STATUS_FILE
        else
                NOL=$(grep -n $CURRENT $STATUS_FILE | awk -F ":" '{print $1}')
                sed -i "$NOL""s/$CURRENT/$1/" $STATUS_FILE
        fi
}
if [ ! -z $PROCESSOR_COMMIT ]; then update_status_file $PROCESSOR_COMMIT $PROCESSOR_REPONAME $PROCESSOR_BRANCH; fi
if [ ! -z $SOURCES_COMMIT ];then update_status_file $SOURCES_COMMIT $SOURCES_REPONAME $SOURCES_BRANCH;  fi
if [ -z $PROCESSOR_BRANCH ]; then
	LAST_PROCESSOR_BRANCH=$(grep $PROCESSOR_REPONAME $STATUS_FILE -A3 | grep "branchName.*$PROCESSOR_BRANCH" -A1 |grep branch | awk -F '"|"' '{print $4}')
	LAST_PROCESSOR_COMMIT=$(grep $PROCESSOR_REPONAME $STATUS_FILE -A3 | grep "branchName.*$PROCESSOR_BRANCH" -A1 | grep commit | awk -F '"|"' '{print $4}')
else
	LAST_PROCESSOR_BRANCH=$(grep $PROCESSOR_REPONAME $STATUS_FILE -A9 | grep "branchName.*$PROCESSOR_BRANCH" -A1 |grep branch | awk -F '"|"' '{print $4}')
	LAST_PROCESSOR_COMMIT=$(grep $PROCESSOR_REPONAME $STATUS_FILE -A9 | grep "branchName.*$PROCESSOR_BRANCH" -A1 | grep commit | awk -F '"|"' '{print $4}')
fi
LAST_SOURCES_COMMIT=$(grep $SOURCES_REPONAME $STATUS_FILE -A2 | grep commit | awk -F '"|"' '{print $4}')

if [ "$LAST_PROCESSOR_BRANCH" == "master" ] || [ "$LAST_PROCESSOR_BRANCH" == "develop" ] || [ "$LAST_PROCESSOR_BRANCH" == "feature/conversion_result_caching" ]; then
        TARGET=(test-target)
        for i in ${TARGET[@]}
        do
                curl http://wpp.isd.dp.ua/jenkins/job/3-irls-lib-processor-convert/buildWithParameters?token=Sheedah8\&TARGET=$i\&PROCESSOR_COMMIT=$LAST_PROCESSOR_COMMIT\&SOURCES_COMMIT=$LAST_SOURCES_COMMIT\&PROCESSOR_BRANCH=$LAST_PROCESSOR_BRANCH
        done
fi

echo \[WARN_MARK\] this job runs job: \<a href="http://wpp.isd.dp.ua/jenkins/job/3-irls-lib-processor-convert"\>3-irls-lib-processor-convert\</a\> \<br\> with one of the parameters TARGET == \<b\>$(echo ${TARGET[@]})\</b\>
