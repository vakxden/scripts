#!/bin/bash

###
### Variables
###
COJ="/var/lib/jenkins/jobs/irls-reader-build/config.xml" # Path to the configuration file of jenkins job
NOF=$(grep -n -A1 "<hudson.plugins.git.BranchSpec>" $COJ | grep name | awk -F "-" '{print $1}') # Number of line (for sed processing)
JUSER="login"
JPASSWD="pass"
CURRENT_BRANCH=$(grep -n -A1 "<hudson.plugins.git.BranchSpec>" /var/lib/jenkins/jobs/irls-reader-build/config.xml | grep name | awk -F"[<>]" '{print $3}') # the current branch in the configuration file of jenkins job
###
### Change branch for "**" to "develop" in the configuration file of jenkins job
###
if [ "$CURRENT_BRANCH" == "**" ]; then
        sed -i "$NOF"'s/\*\*/develop/' $COJ
fi
###
### Deploy the configuration file of jenkins job to jenkins(web)
###
wget --auth-no-challenge --user="$JUSER" --password="$JPASSWD" --post-file="$COJ" --no-check-certificate http://wpp.isd.dp.ua/jenkins/job/irls-reader-build/config.xml
###
### Run of job
###
curl http://wpp.isd.dp.ua/jenkins/job/irls-reader-build/buildWithParameters?token=Sheedah8\&FACET=
###
### Cancel changes to the configuration file of jenkins job
###
if [ "$CURRENT_BRANCH" == "develop" ]; then
        sed -i "$NOF"'s/develop/\*\*/' $COJ
fi
###
### Deploy the configuration file of jenkins job to jenkins(web)
###
wget --auth-no-challenge --user="$JUSER" --password="$JPASSWD" --post-file="$COJ" --no-check-certificate http://wpp.isd.dp.ua/jenkins/job/irls-reader-build/config.xml
