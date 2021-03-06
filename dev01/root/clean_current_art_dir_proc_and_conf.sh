#!/bin/bash

# Current artifacts directory
CURRENT_ART_DIR="/home/jenkins/irls-reader-artifacts"
BRANCHES_JSON="/home/jenkins/irls-reader-artifacts/branches.json"
SIZE=15728640 # 15 Gb

if (($(du -s $CURRENT_ART_DIR/ | awk '{print $1}') > $SIZE));
then
	echo "Before:"
	echo "$CURRENT_ART_DIR used $(du -s $CURRENT_ART_DIR/ | awk '{print $1}') kilobytes"
	echo "$CURRENT_ART_DIR used more then $SIZE kilobytes"
	echo ""
	SCRIPT_NAME=$(basename $0)
	TMP_FILE="/tmp/tmpfile-$SCRIPT_NAME"
	cat /dev/null > $TMP_FILE
	
	#
	### remove unused apache config files
	#

	# determine PID list of running node-processes from not-develop (not-master and not-audio) branches (branches like as 'feature*' or 'hotfix*' or 'test*' or "bugfix*")
	declare -a LIST_OF_NODE_PID
	LIST_OF_NODE_PID=($(ps aux | grep node.*current.js | egrep -v "develop|master|audio|grep node" | awk '{print $2}'))
	# if PID list not empty
	if ((${#LIST_OF_NODE_PID[@]}>0))
	then
		echo "Array LIST_OF_NODE_PID not empty"
		LENGTH_OF_LIST=${#LIST_OF_NODE_PID[@]}
		echo "length of array LIST_OF_NODE_PID is $LENGTH_OF_LIST"
		# for each PID from the PID list
		for (( i=0; i<$LENGTH_OF_LIST; i++ ));
		do
			# determine of port
			PORT_NUMBER=$(netstat -nlpt | grep "${LIST_OF_NODE_PID[$i]}/node" | awk '{print $4}' | sed 's/0.0.0.0://g')
			# check contain this port in apache config file: if not - kill this process
			if ! grep -lr $PORT_NUMBER /etc/apache2/sites-enabled/
			then
				echo "node process is exists but apache config file not exist"
				echo "kill node process ${LIST_OF_NODE_PID[i]}"
				kill -9 ${LIST_OF_NODE_PID[i]}
			fi
		done
		echo ""
	fi
	
	# determine list of apache config files
	declare -a LIST_OF_APACHE_CONF_FILES
	LIST_OF_APACHE_CONF_FILES=($(ls /etc/apache2/sites-enabled/irls-current-reader-*  | egrep -v "develop|master|audio"))
	# if list of apache config files not empty
	if ((${#LIST_OF_APACHE_CONF_FILES[@]}>0))
	then
		echo "Array LIST_OF_APACHE_CONF_FILES not empty"
		LENGTH_OF_LIST=${#LIST_OF_APACHE_CONF_FILES[@]}
		echo "length of array LIST_OF_APACHE_CONF_FILES is $LENGTH_OF_LIST"
		# for each apache config
		for (( i=0; i<$LENGTH_OF_LIST; i++ ));
		do
			# determine of port
			PORT_NUMBER=$(grep "ProxyPass.*127.0.0.1:" ${LIST_OF_APACHE_CONF_FILES[$i]} | awk -F "127.0.0.1:" '{print $2}' | sort | uniq | sed 's/\///g')
			# if this port not up - remove apache config and artifact directory
			if ! netstat -nlpt | grep $PORT_NUMBER
			then
				echo "apache config ${LIST_OF_APACHE_CONF_FILES[$i]} is exists but node process not exist"
				ART_DIR=$(grep irls-reader-artifacts ${LIST_OF_APACHE_CONF_FILES[$i]} | awk '{print $3}' | sort | uniq | awk -F "/" '{print $5}')
				echo "remove artifact directory $CURRENT_ART_DIR/$ART_DIR"
				rm -rf $CURRENT_ART_DIR/$ART_DIR
				echo "remove apache config ${LIST_OF_APACHE_CONF_FILES[$i]}"
				rm -f ${LIST_OF_APACHE_CONF_FILES[$i]}
			fi
		done
		echo ""
	fi
	
	# determine list of deployed branches
	declare -a LIST_OF_BRANCHES
	cd /etc/apache2/sites-enabled/
	LIST_OF_BRANCHES=($(ls irls-current-reader-* | egrep -v "develop|master|audio" | sed -e 's@irls-current-reader-[a-z_-]*-bugfix-@bugfix\/@g' -e 's@irls-current-reader-[a-z_-]*-feature-@feature\/@g' -e 's@irls-current-reader-[a-z_-]*-hotfix-@hotfix\/@g' -e 's@irls-current-reader-[a-z_-]*-test-@test\/@g' | sort | uniq))
	# if list of branches not empty
	if ((${#LIST_OF_BRANCHES[@]}>0))
	then
		echo "Array LIST_OF_BRANCHES not empty"
		LENGTH_OF_LIST=${#LIST_OF_BRANCHES[@]}
		echo "length of array LIST_OF_BRANCHES is $LENGTH_OF_LIST"
		# for each branch
		for (( branch=0; branch<$LENGTH_OF_LIST; branch++ ));
		do
			# determine alive branch
			# whether this is an actual branch
			if ! egrep -q '"'${LIST_OF_BRANCHES[$branch]}'",$|"'${LIST_OF_BRANCHES[$branch]}'"$' $BRANCHES_JSON
			then
				echo "branch ${LIST_OF_BRANCHES[$branch]} is not actual ( not contain in the file $BRANCHES_JSON)"
				# determine config files with this branch
				declare -a LIST_OF_APACHE_CONF_FILES
				LIST_OF_APACHE_CONF_FILES=($(ls irls-current-reader-*$(echo ${LIST_OF_BRANCHES[$branch]} | sed 's/\//-/g')))
				LENGTH_OF_LIST=${#LIST_OF_APACHE_CONF_FILES[@]}
				if ((${#LIST_OF_BRANCHES[@]}>0))
				then
					# for each apache config
					for (( i=0; i<$LENGTH_OF_LIST; i++ ));
					do
						# determine of port
						PORT_NUMBER=$(grep "ProxyPass.*127.0.0.1:" ${LIST_OF_APACHE_CONF_FILES[$i]} | awk -F "127.0.0.1:" '{print $2}' | sort | uniq | sed 's/\///g')
						# remove apache config and artifact directory and kill of node process
						PID=$(netstat -nlpt | grep $PORT_NUMBER | awk '{print $7}' | sed 's/\/node//g')
						echo "kill node process $PID"
						kill -9 $PID
						ART_DIR=$(grep irls-reader-artifacts ${LIST_OF_APACHE_CONF_FILES[$i]} | awk '{print $3}' | sort | uniq | awk -F "/" '{print $5}')
						echo "remove artifact directory $CURRENT_ART_DIR/$ART_DIR"
						rm -rf $CURRENT_ART_DIR/$ART_DIR
						echo "remove apache config ${LIST_OF_APACHE_CONF_FILES[$i]}"
						rm -f ${LIST_OF_APACHE_CONF_FILES[$i]}
					done
				fi
			fi
		done
		echo ""
	fi


	#
        ### determining for artifacts directory and filling of tmp-file
        #
	
        # list of apache config files
	cd
        LIST_APACHE_CONFIGS=$(ls /etc/apache2/sites-enabled/irls-current-reader-*)
        for apache_config_file in $LIST_APACHE_CONFIGS
        do
               # determine for artifacts directory
               EXCLUDED_ART_DIR=$(grep irls-reader-artifacts $apache_config_file | awk '{print $3}' | uniq | awk -F "/" '{print $5}')
               COUNT_LINES_TMP_FILE="$(cat $TMP_FILE | wc -l)"
               # fill tmp-file
               if [ "$COUNT_LINES_TMP_FILE" = "0" ]; then
                       echo "ls -oAtrL $CURRENT_ART_DIR | grep  "^d" | grep -v json |"  >> $TMP_FILE
                       printf  " grep -v $EXCLUDED_ART_DIR |" >> $TMP_FILE
               else
                       printf  " grep -v $EXCLUDED_ART_DIR |" >> $TMP_FILE
               fi
        done
        echo " awk '{print \$8}'" >> $TMP_FILE
        LIST_OF_DELETED_DIRS=$(cat $TMP_FILE | tr '\n' ' ' | xargs -0 bash -c)
        COUNT_LINES=$(cat $TMP_FILE | tr '\n' ' ' | xargs -0 bash -c | wc -l)
        # remove of artifacts directories
        cd $CURRENT_ART_DIR
	A=$(cat $TMP_FILE | tr '\n' ' ' | xargs -0 bash -c | tail -"$COUNT_LINES")
        if [ -z $A ]
        then
                echo "Nothing to delete"
        else
                echo "Removing of the next UNUSED artifacts directories: $(cat $TMP_FILE | tr '\n' ' ' | xargs -0 bash -c | tail -"$COUNT_LINES")"
                cat $TMP_FILE | tr '\n' ' ' | xargs -0 bash -c | tail -"$COUNT_LINES" | xargs rm -rf
        fi
	echo ""

	ART_CURRENT_PATH="/home/jenkins/irls-reader-artifacts"
	for apache_config in $(ls /etc/apache2/sites-enabled/irls-current-reader-*)
	do
		PORT=$(grep "http://127.0.0.1:" $apache_config | awk '{print $3}' | sort | uniq | awk -F ":" '{print $3}' | sed 's@\/@@g')
		PID_NODE_PROCESS=$(netstat -nlpt | grep $PORT | awk '{print $7}' | sed 's@\/node@@g')
		ARTIFACTS_DIRECTORY=$(grep "http://127.0.0.1/" $apache_config | awk '{print $3}' | sort | uniq | awk -F "/" '{print $5}')
		if [ -z $PID_NODE_PROCESS ]; then rm -rf $ART_CURRENT_PATH/$ARTIFACTS_DIRECTORY $apache_config && echo "remove $ART_CURRENT_PATH/$ARTIFACTS_DIRECTORY and  $apache_config because pid of node process on the port $PORT from apache config $apache_config is not exist"; fi
		if [ ! -d $ART_CURRENT_PATH/$ARTIFACTS_DIRECTORY ]; then kill -9 $PID_NODE_PROCESS && rm -f $apache_config && echo "Directory $ART_CURRENT_PATH/$ARTIFACTS_DIRECTORY not found. Kill of node process $PID_NODE_PROCESS and remove apache config $apache_config"; fi
	done
	echo ""


	echo "After:"
	echo "$CURRENT_ART_DIR used $(du -s $CURRENT_ART_DIR/ | awk '{print $1}') kilobytes"
	/usr/sbin/service apache2 stop
	sleep 1
	/usr/sbin/service apache2 start
fi
