#!/bin/bash

ART_CURRENT_DIR="/home/jenkins/irls-reader-artifacts/"

# list of names of running node-processes from not-develop branches (branches like as 'feature*' or 'hotfix*' or 'test*')
LIST=($(ps aux | grep node | egrep -v "STAGE|NIGHT|grep node" | awk '{print $12}' | sed 's@server\/index_@@g' | sed 's@.js@@g'  | sed 's/[a-z_-]*_feature-/feature\//g' | grep -v develop | egrep "feature|hotfix|test" | sort | uniq))

# kill node with unused branches and remove apache proxy- files and artifacts directories
for i in ${LIST[@]}
do
        if ! egrep -q '"'$i'",$|"'$i'"$' branches.json; then
                ps aux | grep node.*$(echo $i | sed -e 's@^feature\/@feature-@g' -e 's@^hotfix\/@hotfix-@g' -e 's@^test\/@test-@g') | grep -v grep | awk '{print $2}' | xargs kill -9
                echo "branch $i is unused, kill the node process"
                y=$(echo $i | sed -e 's@^feature\/@feature-@g' -e 's@^hotfix\/@hotfix-@g' -e 's@^test\/@test-@g'); APACHEFILE=($( ls -f /etc/apache2/sites-enabled/irls-current-reader-*-$y))
                # determine directory for future deleting
                for z in ${APACHEFILE[@]}
                do
                        DELDIR=($(head -2 $z | awk '{print $3}' | awk -F '/' '{print $5}' | sort | uniq))
                        echo "deleting file $z and directory $ART_CURRENT_DIR$DELDIR"
                        rm -f $z
                        rm -rf $ART_CURRENT_DIR$DELDIR
                done
        fi
done
