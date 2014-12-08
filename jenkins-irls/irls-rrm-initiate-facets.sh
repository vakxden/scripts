PROCESSOR_REPONAME="lib-processor"
SOURCES_REPONAME="lib-sources"

STATUS_FILE="status.json"
if [ ! -f $STATUS_FILE ]; then
        touch $STATUS_FILE
        echo -e '{\n\t"lib-processor" : {\n\t\t"commitID":"123",\n\t\t"branchName":"blabla"\n\t},\n\t"lib-sources" : {\n\t\t"commitID":"456",\n\t\t"branchName":"bloblo"\n\t}\n}' >> $STATUS_FILE
fi

function update_status_file {
	# $1 = received commit (or branch)
	# $2 = reponame
	# $3 = update "commit" or "branch"
	if [ -z $1 ]; then
		CURRENT=$(grep $2 $STATUS_FILE -A2 | grep $3 | awk -F '"|"' '{print $4}')
	else
		CURRENT=$(grep $2 $STATUS_FILE -A2 | grep $3 | awk -F '"|"' '{print $4}')
        	if [ "$1" == "$CURRENT" ]; then
        	        echo received $3 from $2 is equal to current $3 from $STATUS_FILE
        	else
        	        NOL=$(grep -n $1 $STATUS_FILE -A2 | grep $3 | awk -F "-" '{print $1}')
        	        sed -i "$NOL""s/$CURRENT/$1/" $STATUS_FILE
        	fi
	fi
}

update_status_file $PROCESSOR_COMMIT $PROCESSOR_REPONAME commit
update_status_file $PROCESSOR_BRANCH $PROCESSOR_REPONAME branch
update_status_file $SOURCES_COMMIT $SOURCES_REPONAME commit
update_status_file $SOURCES_BRANCH $SOURCES_REPONAME branch

LAST_PROCESSOR_COMMIT=$(grep $PROCESSOR_REPONAME $STATUS_FILE -A2 | grep commit | awk -F '"|"' '{print $4}')
LAST_SOURCES_COMMIT=$(grep $SOURCES_REPONAME $STATUS_FILE -A2 | grep commit | awk -F '"|"' '{print $4}')

if [ "$PROCESSOR_BRANCH" = "master" ] || [ "PROCESSOR_BRANCH" = "" ]; then
        TARGET=(ffa ocean)
        for i in ${TARGET[@]}
        do
                curl http://wpp.isd.dp.ua/jenkins/job/irls-rrm-processor-convert/buildWithParameters?token=Sheedah8\&TARGET=$i\&PROCESSOR_COMMIT=$LAST_PROCESSOR_COMMIT\&SOURCES_COMMIT=$LAST_SOURCES_COMMIT
        done
fi

