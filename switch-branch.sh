#!/bin/bash

###
### Variables
###
COJ="/var/lib/jenkins/jobs/irls-reader-build/config.xml" # Path to the configuration file of jenkins job
NOL=$(grep -n -A1 "<hudson.plugins.git.BranchSpec>" $COJ | grep name | awk -F "-" '{print $1}') # Number of line (for sed processing)
JUSER="user"
JPASSWD="pass"
CURRENT_BRANCH=$(grep -n -A1 "<hudson.plugins.git.BranchSpec>" /var/lib/jenkins/jobs/irls-reader-build/config.xml | grep name | awk -F"[<>]" '{print $3}') # the current branch in the configuration file of jenkins job
###
### Change branch for "**" to "develop" in the configuration file of jenkins job
###
function switch_to_develop {
        if [ "$CURRENT_BRANCH" == "**" ]; then
                sed -i "$NOL"'s/\*\*/develop/' $COJ
        fi
}
###
### Deploy the configuration file of jenkins job to jenkins(web)
###
function deploy_conf_file {
        wget --auth-no-challenge --user="$JUSER" --password="$JPASSWD" --post-file="$COJ" --no-check-certificate http://wpp.isd.dp.ua/jenkins/job/irls-reader-build/config.xml
}
###
### Run of job
###
function run_of_job {
        curl http://wpp.isd.dp.ua/jenkins/job/irls-reader-build/buildWithParameters?token=Sheedah8\&FACET=
}
###
### Cancel changes to the configuration file of jenkins job
###
function switch_to_all {
        if [ "$CURRENT_BRANCH" == "develop" ]; then
                sed -i "$NOL"'s/develop/\*\*/' $COJ
        fi
}

case $1 in
        current)
                if [ "$CURRENT_BRANCH" == "**" ]; then
                        echo Current branch is \"all\"
                else
                        echo Current branch is \"$CURRENT_BRANCH\"
                fi
        ;;
        switch_to_develop)
                switch_to_develop
                deploy_conf_file
        ;;
        switch_to_all)
                switch_to_all
                deploy_conf_file
        ;;
        run_of_job)
                run_of_job
        ;;
        *)
                echo "Usage: ./switch-branch.sh {current|switch_to_develop|switch_to_all|run_of_job}"
                exit 1
        ;;

esac
