#This job modifies the configuration file of the job named "2-irls-lib-initiate-targets" ( http://wpp.isd.dp.ua/jenkins/job/2-irls-lib-initiate-targets )

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
COJ_CONV="/var/lib/jenkins/jobs/2-irls-lib-initiate-targets/config.xml" # Path to the configuration file of jenkins job
NUM_CONV=$(grep -n "TARGET=" $COJ_CONV | grep -v "#TARGET=" | grep -v curl | awk -F ":" '{print $1}')
TARGET_CONV=$(grep "TARGET=" $COJ_CONV  | grep -v "#TARGET=" | grep -v curl | awk -F"[()]" '{print $2}')
JUSER="dvac"
JUSER_TOKEN="0f64d6238d107249f79deda4d6a2f9fc"
JSON="/home/jenkins/irls-reader-artifacts/irls-reader-build.json"

###
### Functions
###
function replace_facet_conv () {
        sed -i "$NUM_CONV""s@$TARGET_CONV@$1@" $COJ_CONV
}

function replace_facet_json () {
        sed -i "$NUM_TARGET""s#\"currentTargetsConverter.*#\"currentTargetsConverter\": \""$1"\",#g" $JSON
}

function deploy_conf_file_conv {
        wget --auth-no-challenge --http-user=$JUSER --http-password=$JUSER_TOKEN --post-file="$COJ_CONV" http://wpp.isd.dp.ua/jenkins/job/2-irls-lib-initiate-targets/config.xml
        rm -f config.xml
}

function run_of_job_conv {
        curl http://wpp.isd.dp.ua/jenkins/job/2-irls-lib-initiate-targets/buildWithParameters?token=Sheedah8\&PROCESSOR_BRANCH=$CONVERT_BRANCH
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

if [ ! -z "$CHANGE_TARGET" ]; then
        replace_facet_conv "$CHANGE_TARGET"
        deploy_conf_file_conv
        sudo chown jenkins:git $JSON
        sudo chmod 664 $JSON
        NUM_TARGET=$(grep currentTargetsConverter $JSON -n | awk -F ":" '{print $1}')
        RRR=$(echo $CHANGE_TARGET)
    #replace_facet_json '$RRR'
        sed -i "$NUM_TARGET""s#\"currentTargetsConverter.*#\"currentTargetsConverter\": \"$RRR\",#g" $JSON
fi
