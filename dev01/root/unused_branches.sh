#!/bin/bash

###
ART_CURRENT_DIR="/home/jenkins/irls-reader-artifacts/"
BRANCHES_JSON="/home/jenkins/irls-reader-artifacts/branches.json"

### list of names of running node-processes from not-develop branches (branches like as 'feature*' or 'hotfix*' or 'test*')
declare -a LIST
LIST=($(ps aux | grep node | egrep -v "_stage|NIGHT|grep node|develop|master|audio" | awk '{print $12}' | sed -e 's@server\/index_[a-z_-]*_feature-@feature\/@g' -e 's@\_current.js@@g' | sort | uniq))

### kill node with unused branches and remove apache proxy- files and artifacts directories
LENGTH_OF_LIST=${#LIST[@]}

for (( i=0; i<${LENGTH_OF_LIST}; i++ ));
do
       ii=$(echo ${LIST[$i]} | sed 's@-@_@g')
       if ! egrep -q '"'${LIST[$i]}'",$|"'${LIST[$i]}'"$' $BRANCHES_JSON && ! egrep -q '"'$ii'",$|"'$ii'"$' $BRANCHES_JSON; then
               PID=$(ps aux | grep node.*$(echo ${LIST[$i]} | sed -e 's@^feature\/@feature-@g' -e 's@^hotfix\/@hotfix-@g' -e 's@^test\/@test-@g') | grep -v grep | awk '{print $2}')
               if [ ! -z $PID ]; then kill -9 $PID; fi
               echo "branch ${LIST[$i]} is unused, kill the node process"
               y=$(echo ${LIST[$i]} | sed -e 's@^feature\/@feature-@g' -e 's@^hotfix\/@hotfix-@g' -e 's@^test\/@test-@g'); APACHEFILE=($(ls -f /etc/apache2/sites-enabled/irls-current-reader-*-$y 2>/dev/null))
               ### determine directory for future deleting
               if [ ! -z $APACHEFILE ]; then
                       for z in ${APACHEFILE[@]}
                       do
                               DELDIR=($(head -2 $z | awk '{print $3}' | awk -F '/' '{print $5}' | sort | uniq))
                               echo "deleting file $z and directory $ART_CURRENT_DIR$DELDIR"
                               rm -f $z
                               rm -rf $ART_CURRENT_DIR$DELDIR
                       done
               fi
       fi
done
