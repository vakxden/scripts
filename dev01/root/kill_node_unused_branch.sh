#!/bin/bash

ART_CURRENT_DIR="/home/jenkins/irls-reader-artifacts/"
cd $ART_CURRENT_DIR

# list of names processes, not develop (branches)
LIST=($(ps aux | grep node | egrep -v "STAGE|NIGHT|grep node" | awk '{print $12}' | sed 's@server\/index_@@g' | sed 's@.js@@g'  | sed 's/[a-z_-]*_feature-/feature\//g' | grep -v develop | egrep "feature|hotfix|test" | sort | uniq))

# kill node with unused branches
for i in ${LIST[@]}
do
        if ! egrep -q '"'$i'",$|"'$i'"$' branches.json; then
                ps aux | grep node.*$(echo $i |  sed 's/feature\//feature-/g') | grep -v grep | awk '{print $2}' | xargs kill -9
                echo "branch $i is unused, kill the node process"
        fi
done


# kill apache proxy- files and artifacts directories
for i in ${LIST[@]}
do
        if ! egrep -q '"'$i'",$|"'$i'"$' branches.json; then
                SEDFILENAME=$(ps aux | grep node | egrep -v "STAGE|NIGHT|grep node" | awk '{print $12}' | sed 's@server\/index_@@g' | sed 's@.js@@g'  | grep -v develop | egrep "feature|hotfix|test" | sed 's@_feature@-feature@g')
                APACHEFILE="/etc/apache2/sites-enabled/irls-current-reader-$SEDFILENAME"
                # determine directory for future deleting
                DELDIR=$(head -2 $APACHEFILE | awk '{print $3}' | awk -F '/' '{print $5}' | sort | uniq)
                echo "deleting file $APACHEFILE and directory $ART_CURRENT_DIR$DELDIR"
                #rm -f $APACHEFILE
                #rm -rf $DELDIR
        fi
done
