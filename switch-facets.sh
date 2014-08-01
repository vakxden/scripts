#!/bin/bash

###
### Variables
###

# $1 - for case
# $2 - add facet
ADD_FACET=$2
COJ="/var/lib/jenkins/jobs/irls-reader-build/config.xml" # Path to the configuration file of jenkins job
NOL1=$(grep -n -A1 "<hudson.plugins.git.BranchSpec>" $COJ | grep name | awk -F "-" '{print $1}') # Number of line (for sed processing)
NOL2=$(grep -A2 -n 'if \[ "$BRANCHNAME" = "develop" \]' $COJ | grep -v "#FACET" | grep "FACET=" | awk -F "-" '{print $1}')
NOL3=$(grep -A5 -n 'if \[ "$BRANCHNAME" = "develop" \]' $COJ | grep -A2 else | grep -v "#FACET" | grep "FACET=" | awk -F "-" '{print $1}' | awk -F "-" '{print $1}')
JUSER="login"
JPASSWD="pass"
CURRENT_BRANCH=$(grep -n -A1 "<hudson.plugins.git.BranchSpec>" $COJ | grep name | awk -F"[<>]" '{print $3}') # the current branch in the configuration file of jenkins job
CURRENT_FACET_DEVELOP=$(grep -A2 -n 'if \[ "$BRANCHNAME" = "develop" \]' $COJ | grep -v "#FACET" | grep "FACET=" | awk -F"[()]" '{print $2}')
CURRENT_FACET_ALL=$(grep -A5 -n 'if \[ "$BRANCHNAME" = "develop" \]' $COJ | grep -A2 else | grep -v "#FACET" | grep "FACET=" | awk -F"[()]" '{print $2}')

function switch_to_develop {
        if [ "$CURRENT_BRANCH" == "**" ]; then
                sed -i "$NOL1"'s/\*\*/develop/' $COJ
        fi
}

function deploy_conf_file {
        wget --auth-no-challenge --user="$JUSER" --password="$JPASSWD" --post-file="$COJ" --no-check-certificate http://wpp.isd.dp.ua/jenkins/job/irls-reader-build/config.xml
}

function run_of_job {
        curl http://wpp.isd.dp.ua/jenkins/job/irls-reader-build/buildWithParameters?token=Sheedah8\&FACET=
}

function switch_to_all {
        if [ "$CURRENT_BRANCH" == "develop" ]; then
                sed -i "$NOL1"'s/develop/\*\*/' $COJ
        fi
}

function add_facet_to_develop () {
        # $1 = $ADD_FACET
        sed -i "$NOL2""s/$CURRENT_FACET_DEVELOP/$CURRENT_FACET_DEVELOP $1/" $COJ
}

function add_facet_to_all () {
        # $1 = $ADD_FACET
        sed -i "$NOL3""s/$CURRENT_FACET_ALL/$CURRENT_FACET_ALL $1/" $COJ
}

case $1 in
        current)
                if [ "$CURRENT_BRANCH" == "**" ]; then
                        echo Current branch is \"all\"
                        echo Current facet is \"$CURRENT_FACET_ALL\"
                else
                        echo Current branch is \"$CURRENT_BRANCH\"
                        echo Current facet is \"$CURRENT_FACET_DEVELOP\"
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
        add_facet_to_develop)
                if [ -z "$2" ]; then
                        echo Parameter FACET_NAME must be passed...
                        echo exit
                        exit 1
                fi
                add_facet_to_develop $ADD_FACET
        ;;
        add_facet_to_all)
                if [ -z "$2" ]; then
                        echo Parameter FACET_NAME must be passed...
                        echo exit
                        exit 1
                fi
                add_facet_to_all $ADD_FACET
        ;;
        *)
                echo "Usage: ./switch-facets.sh {current|switch_to_develop|switch_to_all|run_of_job|add_facet_to_develop FACET_NAME|add_facet_to_all FACET_NAME}"
                exit 1
        ;;

esac
