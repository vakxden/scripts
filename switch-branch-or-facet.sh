#This job modifies the configuration file of the job named "irls-reader-build" ( http://wpp.isd.dp.ua/jenkins/job/irls-reader-build )

#Name of job: switch-branch-or-facet ( http://wpp.isd.dp.ua/jenkins/job/switch-branch-or-facet )
#Authentication Token: neLei5ie
#Parameters of this job:
#       SWITCH_BRANCH - option to change the branch which focuses job, may be "switch_branch_to_develop" or "switch_branch_to_all"
#       RUN_OF_JOB - option to run the job, may be "run_of_job"
#       CHANGE_FACET - list of facets that will be passed to the job (e.g. "farsi3 audiobywords audio puddle") - Deprecated!!!
#       CHANGE_TARGET - list of targetss that will be passed to the job
#       BRANCH - target branch for which will be changed  the list of facets, may be "all" or "develop"

###
### Variables
###

COJ="/var/lib/jenkins/jobs/irls-reader-build/config.xml" # Path to the configuration file of jenkins job
#LIST_OF_ALL_FACETS=$(grep list_of_all_facets $COJ | awk -F"[()]" '{print $2}')
TARGETS_REPO="git@wpp.isd.dp.ua:irls/targets.git"
TARGETS_REPO_DIR_NAME=$(echo $TARGETS_REPO | cut -d":" -f2 | cut -d"/" -f2 | sed s@.git@@g)
### Clone or "git pull" (if exist) targets-repo
if [ ! -d $WORKSPACE/$TARGETS_REPO_DIR_NAME ]; then
        cd $WORKSPACE && git clone $TARGETS_REPO
else
        cd $WORKSPACE/$TARGETS_REPO_DIR_NAME && git pull
fi
LIST_OF_ALL_TARGETS=($(cd $WORKSPACE/$TARGETS_REPO_DIR_NAME; ls -d ./* | sed s@\./@@g ));
NOL1=$(grep -n -A1 "<hudson.plugins.git.BranchSpec>" $COJ | grep name | awk -F "-" '{print $1}') # Number of line (for sed processing)
#NOL2=$(grep -A2 -n 'if.*BRANCHNAME.*develop' $COJ | grep -v "#FACET" | grep "FACET=" | awk -F "-" '{print $1}')
NOL2=$(grep -A2 -n 'if.*BRANCHNAME.*develop' $COJ | grep -v "#TARGET" | grep "TARGET=" | awk -F "-" '{print $1}')
#NOL3=$(grep -A5 -n 'if.*BRANCHNAME.*develop' $COJ | grep -A2 else | grep -v "#FACET" | grep "FACET=" | awk -F "-" '{print $1}' | awk -F "-" '{print $1}')
NOL3=$(grep -A5 -n 'if.*BRANCHNAME.*develop' $COJ | grep -A2 else | grep -v "#TARGET" | grep "TARGET=" | awk -F "-" '{print $1}' | awk -F "-" '{print $1}')
JUSER="dvac"
CURRENT_BRANCH=$(grep -n -A1 "<hudson.plugins.git.BranchSpec>" $COJ | grep name | awk -F"[<>]" '{print $3}') # the current branch in the configuration file of jenkins job
#CURRENT_FACET_DEVELOP=$(grep -A2 -n 'if.*BRANCHNAME.*develop' $COJ | grep -v "#FACET" | grep "FACET=" | awk -F"[()]" '{print $2}')
CURRENT_TARGET_DEVELOP=$(grep -A2 -n 'if.*BRANCHNAME.*develop' $COJ | grep -v "#TARGET" | grep "TARGET=" | awk -F"[()]" '{print $2}')
#CURRENT_FACET_ALL=$(grep -A5 -n 'if.*BRANCHNAME.*develop' $COJ | grep -A2 else | grep -v "#FACET" | grep "FACET=" | awk -F"[()]" '{print $2}')
CURRENT_TARGET_ALL=$(grep -A5 -n 'if.*BRANCHNAME.*develop' $COJ | grep -A2 else | grep -v "#TARGET" | grep "TARGET=" | awk -F"[()]" '{print $2}')
JUSER_TOKEN="0f64d6238d107249f79deda4d6a2f9fc"
JSON_FILE="/home/jenkins/irls-reader-artifacts/irls-reader-build.json"

function switch_to_develop {
        if [ "$CURRENT_BRANCH" == "**" ]; then
                sed -i "$NOL1"'s/\*\*/develop/' $COJ
        fi
}

function deploy_conf_file {
        wget --auth-no-challenge --http-user=$JUSER --http-password=$JUSER_TOKEN --post-file="$COJ" http://wpp.isd.dp.ua/jenkins/job/irls-reader-build/config.xml
        rm -f config.xml
}

function run_of_job {
        #curl http://wpp.isd.dp.ua/jenkins/job/irls-reader-build/buildWithParameters?token=Sheedah8\&FACET=
        curl http://wpp.isd.dp.ua/jenkins/job/irls-reader-build/buildWithParameters?token=Sheedah8\&TARGET=
}

function switch_to_all {
        if [ "$CURRENT_BRANCH" == "develop" ]; then
                sed -i "$NOL1"'s/develop/\*\*/' $COJ
        fi
}

function replace_facet () {
        # $1 = $BRANCH
        # $2 = $CHANGE_FACET - Deprecated!!!
        # $2 = $CHANGE_TARGET
        if [ "$1" = "all" ]; then
                sed -i "$NOL3""s/$CURRENT_TARGET_ALL/$2/" $COJ
        elif [ "$1" = "develop" ]; then
                sed -i "$NOL2""s/$CURRENT_TARGET_DEVELOP/$2/" $COJ
        fi
}

if [ "$SWITCH_BRANCH" = "switch_branch_to_develop" ]; then
        switch_to_develop
        deploy_conf_file
elif [ "$SWITCH_BRANCH" = "switch_branch_to_all" ]; then
        switch_to_all
        deploy_conf_file
elif [ "$SWITCH_BRANCH" = "" ]; then
        printf "Parameter SWITCH_BRANCH is null"
else
        printf "Parameter SWITCH_BRANCH must be \"switch_branch_to_develop\" or \"switch_branch_to_all\". Not \"$SWITCH_BRANCH\" \n"
        exit 1
fi

if [ "$RUN_OF_JOB" = "run_of_job" ]; then
        run_of_job
elif [ "$RUN_OF_JOB" = "" ]; then
        printf "Parameter RUN_OF_JOB is null"
else
        printf "Parameter RUN_OF_JOB must be \"run_of_job\". Not \"$RUN_OF_JOB\" \n"
        exit 1
fi

#checking for the existence of a parameter "BRANCH" occurs only when the parameter "CHANGE_FACET" is present - Deprecated!!!
#checking for the existence of a parameter "BRANCH" occurs only when the parameter "CHANGE_TARGET" is present
#if [ ! -z "$CHANGE_FACET" ]; then
if [ ! -z "$CHANGE_TARGET" ]; then
        if [ "$BRANCH" = "all" ] || [ "$BRANCH" = "develop" ]; then
                replace_facet "$BRANCH" "$CHANGE_TARGET"
                deploy_conf_file
        else
                printf "Parameter BRANCH must be \"all\" or \"develop\". Not \"$BRANCH\" \n"
                exit 1
        fi
fi

#generating of json-file
#if grep "currentFacetsConverter" $JSON_FILE; then - Deprecated!!!
if grep "currentTargetsConverter" $JSON_FILE; then
        #CGC=$(grep "currentFacetsConverter" $JSON_FILE) ### preserve "currentFacetsConverter"- Deprecated!!!
        CGC=$(grep "currentTargetsConverter" $JSON_FILE) ### preserve "currentTargetsConverter"
        echo "CGC=$CGC"
fi
LAST_BRANCH_READER=$(grep lastReaderBranchCommit $JSON_FILE | awk -F'["|"]' '{print $4}')
sudo chown jenkins:git /home/jenkins/irls-reader-artifacts/irls-reader-build.json
sudo chmod 664 /home/jenkins/irls-reader-artifacts/irls-reader-build.json
cat /dev/null > $JSON_FILE
VJF_CURRENT_BRANCH=$(grep -n -A1 "<hudson.plugins.git.BranchSpec>" $COJ | grep name | awk -F"[<>]" '{print $3}') #variable for json-file
#VJF_CURRENT_FACET_ALL=$(grep -A5 -n 'if.*BRANCHNAME.*develop' $COJ | grep -A2 else | grep -v "#FACET" | grep "FACET=" | awk -F"[()]" '{print $2}')
VJF_CURRENT_TARGET_ALL=$(grep -A5 -n 'if.*BRANCHNAME.*develop' $COJ | grep -A2 else | grep -v "#TARGET" | grep "TARGET=" | awk -F"[()]" '{print $2}')
#VJF_CURRENT_FACET_DEVELOP=$(grep -A2 -n 'if.*BRANCHNAME.*develop' $COJ | grep -v "#FACET" | grep "FACET=" | awk -F"[()]" '{print $2}')
VJF_CURRENT_TARGET_DEVELOP=$(grep -A2 -n 'if.*BRANCHNAME.*develop' $COJ | grep -v "#TARGET" | grep "TARGET=" | awk -F"[()]" '{print $2}')
echo -e "{" >> $JSON_FILE
if [ "$VJF_CURRENT_BRANCH" == "**" ]; then
        echo -e "\t\"currentBranch\":  \"all\"," >> $JSON_FILE
else
        echo -e "\t\"currentBranch\":  \""$VJF_CURRENT_BRANCH"\"," >> $JSON_FILE
fi
#echo -e "\t\"currentFacetsNotDevelop\": \""$VJF_CURRENT_FACET_ALL"\"," >> $JSON_FILE
echo -e "\t\"currentTargetsNotDevelop\": \""$VJF_CURRENT_TARGET_ALL"\"," >> $JSON_FILE
#echo -e "\t\"listOfAllFacets\": \""$LIST_OF_ALL_FACETS"\"," >> $JSON_FILE
echo -e "\t\"listOfAllTargets\": \""${LIST_OF_ALL_TARGETS[@]}"\"," >> $JSON_FILE
echo -e "\t\"lastReaderBranchCommit\": \""$LAST_BRANCH_READER"\"," >> $JSON_FILE
echo -e "$CGC" >> $JSON_FILE
#echo -e "\t\"currentFacetsDevelop\": \""$VJF_CURRENT_FACET_DEVELOP"\"" >> $JSON_FILE
echo -e "\t\"currentTargetsDevelop\": \""$VJF_CURRENT_TARGET_DEVELOP"\"" >> $JSON_FILE
echo -e "}" >> $JSON_FILE
