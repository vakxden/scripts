#This job modifies the configuration file of the job named "irls-rrm-initiate-facets" ( http://wpp.isd.dp.ua/jenkins/job/irls-rrm-initiate-facets )

#Name of job: switch-converter-facet ( http://wpp.isd.dp.ua/jenkins/job/switch-converter-facet )
#Authentication Token: neLei5ie
#Parameters of this job:
#       RUN_OF_JOB - option to run the job, may be "run_of_job"
#       CHANGE_FACET - list of facets that will be passed to the job (e.g. "farsi3 audiobywords audio puddle") - Deprecated!!!
#       CHANGE_TARGET - list of facets that will be passed to the job

###
### Variables
###
URL_CONV=""
COJ_CONV="/var/lib/jenkins/jobs/irls-rrm-initiate-facets/config.xml" # Path to the configuration file of jenkins job
#NUM_CONV=$(grep -n "FACET=" $COJ_CONV | grep -v "#FACET=" | grep -v curl | awk -F ":" '{print $1}')
NUM_CONV=$(grep -n "TARGET=" $COJ_CONV | grep -v "#TARGET=" | grep -v curl | awk -F ":" '{print $1}')
#FACET_CONV=$(grep "FACET=" $COJ_CONV  | grep -v "#FACET=" | grep -v curl | awk -F"[()]" '{print $2}')
TARGET_CONV=$(grep "TARGET=" $COJ_CONV  | grep -v "#TARGET=" | grep -v curl | awk -F"[()]" '{print $2}')
JUSER="dvac"
JUSER_TOKEN="0f64d6238d107249f79deda4d6a2f9fc"
JSON="/home/jenkins/irls-reader-artifacts/irls-reader-build.json"

###
### Functions
###
function replace_facet_conv () {
	#sed -i "$NUM_CONV""s/$FACET_CONV/$1/" $COJ_CONV
	sed -i "$NUM_CONV""s@$TARGET_CONV@$1@" $COJ_CONV
}

function replace_facet_json () {
	#sed -i "$NUM_FACET""s#\"currentFacetsConverter.*#\"currentFacetsConverter\": \""$1"\",#g" $JSON
	sed -i "$NUM_TARGET""s#\"currentTargetsConverter.*#\"currentTargetsConverter\": \""$1"\",#g" $JSON
}

function deploy_conf_file_conv {
        wget --auth-no-challenge --http-user=$JUSER --http-password=$JUSER_TOKEN --post-file="$COJ_CONV" http://wpp.isd.dp.ua/jenkins/job/irls-rrm-initiate-facets/config.xml
        rm -f config.xml
}

function run_of_job_conv {
        curl http://wpp.isd.dp.ua/jenkins/job/irls-rrm-initiate-facets/buildWithParameters?token=Sheedah8\&BRANCHNAME=
}

###
### Main
###
if [ "$RUN_OF_JOB" = "run_of_job" ]; then
        run_of_job_conv
elif [ "$RUN_OF_JOB" = "" ]; then
        printf "Parameter RUN_OF_JOB is null"
else
        printf "Parameter RUN_OF_JOB must be \"run_of_job\". Not \"$RUN_OF_JOB\" \n"
        exit 1
fi

#if [ ! -z "$CHANGE_FACET" ]; then
if [ ! -z "$CHANGE_TARGET" ]; then
	#replace_facet_conv "$CHANGE_FACET"
	replace_facet_conv "$CHANGE_TARGET"
	deploy_conf_file_conv
	sudo chown jenkins:git $JSON
	sudo chmod 664 $JSON
	#NUM_FACET=$(grep currentFacetsConverter $JSON -n | awk -F ":" '{print $1}')
	NUM_TARGET=$(grep currentTargetsConverter $JSON -n | awk -F ":" '{print $1}')
	#RRR=$(echo $CHANGE_FACET)
	RRR=$(echo $CHANGE_TARGET)
    #replace_facet_json '$RRR'
	#sed -i "$NUM_FACET""s#\"currentFacetsConverter.*#\"currentFacetsConverter\": \"$RRR\",#g" $JSON
	sed -i "$NUM_TARGET""s#\"currentTargetsConverter.*#\"currentTargetsConverter\": \"$RRR\",#g" $JSON
fi
