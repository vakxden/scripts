#!/bin/bash

BRANCHES_JSON="/home/jenkins/irls-reader-artifacts/branches.json"
COUCH_PATH="/home/couchdb/"
ENVIRONMENT="current"
FOUND_BRANCH=($(find $COUCH_PATH -name .$ENVIRONMENT-* -o -name $ENVIRONMENT-* | grep feature | sed "s#$COUCH_PATH\($ENVIRONMENT-\|.$ENVIRONMENT-\)##g" | awk -F "_" '{print $1}' | sort | uniq))
for fbranch in ${FOUND_BRANCH[@]}
do
        fbranch1=$(echo $fbranch | sed "s#feature-#feature\/#g")
        fbranch2=$(echo $fbranch | sed -e "s#feature-#feature\/#g" -e "s#-#_#g")
        if ! egrep -q '"'$fbranch1'",$|"'$fbranch1'"$' $BRANCHES_JSON && ! egrep -q '"'$fbranch2'",$|"'$fbranch2'"$' $BRANCHES_JSON; then
                rm -rf $COUCH_PATH$ENVIRONMENT-$fbranch* or $COUCH_PATH.$ENVIRONMENT-$fbranch*
        fi
done
