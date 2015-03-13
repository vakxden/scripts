# Check input variables
if [ -z $REPONAME ]; then
	echo \[ERROR_REPO\] reponame not passed!
	exit 1
fi

if [ -z $BRANCH ]; then
	echo \[ERROR_BRANCH\] branch not passed!
	exit 1
fi

# Variables
JENKINS_URL="http://wpp.isd.dp.ua/jenkins/job"
PRODUCT_REPO="product-replica"
TARGETS_REPO="targets-replica"
JSON_FILE="$TARGETS_REPO.json"
REMOTE_JSON_FILE="http://wpp.isd.dp.ua/irls-reader-artifacts/$JSON_FILE"
curl -s $REMOTE_JSON_FILE > $JSON_FILE
COUNT_OF_LINES=$(cat $JSON_FILE | wc -l)

# Functions
function run_of_job () {
	curl $JENKINS_URL/$1/buildWithParameters?token=Sheedah8\&TARGET=$target\&BRANCHNAME=$2\&STARTED_BY=$JOB_NAME%20$BUILD_NUMBER
}

function check_and_start_job () {
	for i in $(seq 1 $COUNT_OF_LINES)
	do
	        target=$(cat $JSON_FILE | sed -n "$i"\ p | awk 'NR>1{print $1}' RS=target_name FS=branch | sed 's@\("\|,\|:\| \)@@g')
	        branches_array=($(cat $JSON_FILE | sed -n "$i"\ p | awk 'NR>1{print $1}' RS=branch FS="\n" | awk 'NR>1{print $1}' RS=\[ FS=\] | sed -e 's@\( \|"\)@@g' -e 's@,@ @g'))
	        if [ -z $target ] || [ -z $branches_array ]; then
	                continue
		else
	        	for branch in ${branches_array[@]}
	        	do
	        	        if [[ $BRANCH == $branch ]]; then
					run_of_job $1 $branch
	        	        fi
	        	done
	        fi
	done
	echo \[WARN_MARK\] Started by commit to repo \<b\>$REPONAME\</b\>\<br\> run the \<a href="$JENKINS_URL/$1" title="$1"\>$1\</a\> job
}

# Body of script
if [ $REPONAME == $PRODUCT_REPO ]; then
	RUNNING_JOB="irls-reader-build-replica"
	check_and_start_job $RUNNING_JOB
#elif [ "$REPONAME" == "lib-processor" ]; then
#        if [ "$BRANCH" == "master" ] || [ "$BRANCH" == "develop" ] || [ "$BRANCH" == "feature/conversion_result_caching" ]; then
#                curl http://wpp.isd.dp.ua/jenkins/job/1-irls-lib-processor-build/buildWithParameters?token=Sheedah8\&BRANCHNAME=$BRANCH
#        fi
#        echo \[WARN_MARK\] Started by commit to repo \<b\>$REPONAME\</b\>\<br\> run the \<a href="http://wpp.isd.dp.ua/jenkins/job/1-irls-lib-processor-build" title="1-irls-lib-processor-build"\>1-irls-lib-processor-build\</a\> job
#elif [ "$REPONAME" == "lib-sources" ]; then
#        if [ "$BRANCH" == "master" ]; then
#                curl http://wpp.isd.dp.ua/jenkins/job/1-irls-lib-sources-build/buildWithParameters?token=Sheedah8\&BRANCHNAME=$BRANCH
#        fi
#        echo \[WARN_MARK\] Started by commit to repo \<b\>$REPONAME\</b\>\<br\> run the \<a href="http://wpp.isd.dp.ua/jenkins/job/1-irls-lib-sources-build" title="1-irls-lib-sources-build"\>1-irls-lib-sources-build\</a\> job
#elif [ "$REPONAME" == "build_re" ]; then
#        curl http://wpp.isd.dp.ua/jenkins/job/build_runtime_engines/buildWithParameters?token=Sheedah8\&REPONAME=$REPONAME\&BRANCH=$BRANCH
#        echo \[WARN_MARK\] Started by commit to repo \<b\>$REPONAME\</b\>\<br\> run the \<a href="http://wpp.isd.dp.ua/jenkins/job/build_runtime_engines" title="build_runtime_engines"\>build_runtime_engines\</a\> job
else
	echo \[ERROR_REPO\] Wrong reponame!
	exit 1
fi
