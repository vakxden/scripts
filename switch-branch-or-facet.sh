
cat /dev/null > switch-facets.sh

cat > switch-facets.sh <<'endmsg'

#!/bin/bash

###
### Variables
###

# $1 - for case
LIST_OF_ALL_FACETS=$(grep list_of_all_facets /var/lib/jenkins/jobs/irls-reader-build/config.xml | awk -F"[()]" '{print $2}')
COJ="/var/lib/jenkins/jobs/irls-reader-build/config.xml" # Path to the configuration file of jenkins job
NOL1=$(grep -n -A1 "<hudson.plugins.git.BranchSpec>" $COJ | grep name | awk -F "-" '{print $1}') # Number of line (for sed processing)
NOL2=$(grep -A2 -n 'if.*BRANCHNAME.*develop' $COJ | grep -v "#FACET" | grep "FACET=" | awk -F "-" '{print $1}')
NOL3=$(grep -A5 -n 'if.*BRANCHNAME.*develop' $COJ | grep -A2 else | grep -v "#FACET" | grep "FACET=" | awk -F "-" '{print $1}' | awk -F "-" '{print $1}')
JUSER="dvac"
CURRENT_BRANCH=$(grep -n -A1 "<hudson.plugins.git.BranchSpec>" $COJ | grep name | awk -F"[<>]" '{print $3}') # the current branch in the configuration file of jenkins job
CURRENT_FACET_DEVELOP=$(grep -A2 -n 'if.*BRANCHNAME.*develop' $COJ | grep -v "#FACET" | grep "FACET=" | awk -F"[()]" '{print $2}')
CURRENT_FACET_ALL=$(grep -A5 -n 'if.*BRANCHNAME.*develop' $COJ | grep -A2 else | grep -v "#FACET" | grep "FACET=" | awk -F"[()]" '{print $2}')
JENKINS_USER_TOKEN="0f64d6238d107249f79deda4d6a2f9fc"

function switch_to_develop {
        if [ "$CURRENT_BRANCH" == "**" ]; then
                sed -i "$NOL1"'s/\*\*/develop/' $COJ
        fi
}

function deploy_conf_file {
        #wget --auth-no-challenge --user="$JUSER" --password="$JPASSWD" --post-file="$COJ" --no-check-certificate http://wpp.isd.dp.ua/jenkins/job/irls-reader-build/config.xml
        wget --auth-no-challenge --http-user=$JUSER --http-password=$JENKINS_USER_TOKEN --post-file="$COJ" http://wpp.isd.dp.ua/jenkins/job/irls-reader-build/config.xml
        rm -f config.xml
}

function run_of_job {
        curl http://wpp.isd.dp.ua/jenkins/job/irls-reader-build/buildWithParameters?token=Sheedah8\&FACET=
}

function switch_to_all {
        if [ "$CURRENT_BRANCH" == "develop" ]; then
                sed -i "$NOL1"'s/develop/\*\*/' $COJ
        fi
}

function replace_facet () {
        # $1 = $BRANCH (develop or all)
        # $2 = $FACET_NAME
        if [ "$1" = "all" ]; then
                sed -i "$NOL3""s/$CURRENT_FACET_ALL/$2/" $COJ
        elif [ "$1" = "develop" ]; then
                sed -i "$NOL2""s/$CURRENT_FACET_DEVELOP/$2/" $COJ
        else
                echo Branch must be \"develop\" or \"all\"
        fi
}

case $1 in
        current)
                if [ "$CURRENT_BRANCH" == "**" ]; then
                        echo Current branch is \"all\"
                        echo Current facet for \"all\" branches is \"$CURRENT_FACET_ALL\"
                        echo Current facet for \"develop\" branch is \"$CURRENT_FACET_DEVELOP\"
                else
                        echo Current branch is \"$CURRENT_BRANCH\"
                        echo Current facet for \"develop\" branch is \"$CURRENT_FACET_DEVELOP\"
                        echo Current facet for \"all\" branches is \"$CURRENT_FACET_ALL\"
                fi
        ;;
        switch_branch_to_develop)
                switch_to_develop
                deploy_conf_file
        ;;
        switch_branch_to_all)
                switch_to_all
                deploy_conf_file
        ;;
        run_of_job)
                run_of_job
        ;;
        change_facet)
                BRANCH="$2"
                FACET_NAME=$3
                if [ -z "$2" ]; then
                        echo Parameter BRANCH must be passed...
                        exit 1
                fi
                if [ -z "$3" ]; then
                        echo Parameter FACET_NAME must be passed...
                        exit 1
                fi
                replace_facet "$BRANCH" "$FACET_NAME"
                deploy_conf_file
        ;;
        *)
                echo "Usage: ./switch-facets.sh {current|switch_branch_to_develop|switch_branch_to_all|run_of_job|change_facet BRANCH FACET_NAME}"
                echo Parameter BRANCH must be \"develop\" or \"all\"
                echo Parameter FACET_NAME must be one word or list, e.g. change_facet \"all\" \"puddle audiobywords farsi3\"
                echo List of all facets is \"$LIST_OF_ALL_FACETS\"
                exit 1
        ;;

esac
endmsg

chmod +x switch-facets.sh

if [ "$SWITCH_BRANCH" = "switch_branch_to_develop" ]; then
	SWITCH_PARAM="switch_branch_to_develop"
	./switch-facets.sh $SWITCH_PARAM
elif [ "$SWITCH_BRANCH" = "switch_branch_to_all" ]; then
	SWITCH_PARAM="switch_branch_to_all"
	./switch-facets.sh $SWITCH_PARAM
fi

if [ "$RUN_OF_JOB" = "run_of_job" ]; then
	RUN_OF_JOB="run_of_job"
	./switch-facets.sh $RUN_OF_JOB
fi

if [ ! -z "$CHANGE_FACET" ]; then
	if [ "$BRANCH" = "all" ]; then
		BRANCH="all"
		./switch-facets.sh change_facet \"$BRANCH\" \"$CHANGE_FACET\"
	elif [ "$BRANCH" = "develop" ]; then
		BRANCH="develop"
		./switch-facets.sh change_facet \"$BRANCH\" \"$CHANGE_FACET\"
	fi
fi
