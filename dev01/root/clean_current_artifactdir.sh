#!/bin/bash

# Current artifacts directory
CURRENT_ART_DIR="/home/jenkins/irls-reader-artifacts"
BRANCHES_JSON="/home/jenkins/irls-reader-artifacts/branches.json"
SIZE=15

if du -hs $CURRENT_ART_DIR/ | grep M ; then exit 0; fi

while (($(du -hs $CURRENT_ART_DIR/ | awk '{print $1}' | sed 's/G//g' | sed 's/\.[0-9]//g') > $SIZE))
do
        printf "$CURRENT_ART_DIR used more then $SIZE Gb\n"
        SCRIPT_NAME=$(basename $0)
        TMP_FILE="/tmp/tmpfile-$SCRIPT_NAME"
        cat /dev/null > $TMP_FILE
        #
        ### remove unused apache config files
        #
        # list of names of running node-processes from not-develop (not-master and not-audio) branches (branches like as 'feature*' or 'hotfix*' or 'test*')
        declare -a LIST
        LIST=($(ps aux | grep node | egrep -v "_stage|NIGHT|grep node|develop_current.js|master_current.js|audio_current.js|main.js|init.js" | awk '{print $12}' | sed -e 's@server\/index_[a-z_-]*_feature-@feature\/@g' -e 's@\_current.js@@g' | sort | uniq))
        # kill node with unused branches and remove apache proxy- files and artifacts directories
        LENGTH_OF_LIST=${#LIST[@]}
        for (( i=0; i<${LENGTH_OF_LIST}; i++ ));
        do
               ii=$(echo ${LIST[$i]} | sed 's@-@_@g')
               if ! egrep -q '"'${LIST[$i]}'",$|"'${LIST[$i]}'"$' $BRANCHES_JSON && ! egrep -q '"'$ii'",$|"'$ii'"$' $BRANCHES_JSON; then
                       PID=($(ps aux | grep node.*$(echo ${LIST[$i]} | sed -e 's@^feature\/@feature-@g' -e 's@^hotfix\/@hotfix-@g' -e 's@^test\/@test-@g') | grep -v grep | awk '{print $2}'))
                        for j in ${PID[@]}
                        do
                                if [ ! -z $j ]; then
                                        kill -9 $j
                                fi
                                echo "branch ${LIST[$i]} is unused, kill the node process"
                                y=$(echo ${LIST[$i]} | sed -e 's@^feature\/@feature-@g' -e 's@^hotfix\/@hotfix-@g' -e 's@^test\/@test-@g'); APACHEFILE=($(ls -f /etc/apache2/sites-enabled/irls-current-reader-*-$y 2>/dev/null))
                                # determine directory for future deleting
                                if [ ! -z $APACHEFILE ]; then
                                        for z in ${APACHEFILE[@]}
                                        do
                                                DELDIR=($(head -2 $z | awk '{print $3}' | awk -F '/' '{print $5}' | sort | uniq))
                                                echo "deleting file $z and directory $CURRENT_ART_DIR/$DELDIR"
                                                rm -f $z
                                                rm -rf $CURRENT_ART_DIR/$DELDIR
                                        done
                                fi
                        done
               fi
        done
        #
        ### determining for artifacts directory and filling of tmp-file
        #
        # list of apache config files
        LIST_APACHE_CONFIGS=$(ls /etc/apache2/sites-enabled/irls-current-reader-*)
        for apache_config_file in $LIST_APACHE_CONFIGS
        do
                # determine for artifacts directory
                EXCLUDED_ART_DIR=($(grep irls-reader-artifacts $apache_config_file | awk '{print $3}' | uniq | awk -F "/" '{print $5}'))
                COUNT_LINES_TMP_FILE="$(cat $TMP_FILE | wc -l)"
                # fill tmp-file
                if [ "$COUNT_LINES_TMP_FILE" = "0" ]; then
                        echo "ls -oAtrL $CURRENT_ART_DIR | grep  "^d" | grep -v json |"  >> $TMP_FILE
                else
                        for excluded_art_dir in ${EXCLUDED_ART_DIR[@]}
                        do
                                printf  " grep -v $excluded_art_dir |" >> $TMP_FILE
                        done
                fi
        done
        echo " awk '{print \$8}'" >> $TMP_FILE
        LIST_OF_DELETED_DIRS=$(cat $TMP_FILE | tr '\n' ' ' | xargs -0 bash -c)
        COUNT_LINES=$(cat $TMP_FILE | tr '\n' ' ' | xargs -0 bash -c | wc -l)
        # remove of artifacts directories
        cd $CURRENT_ART_DIR
        cat $TMP_FILE | tr '\n' ' ' | xargs -0 bash -c | tail -"$COUNT_LINES" | xargs rm -rf
done
