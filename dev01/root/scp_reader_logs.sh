#!/bin/bash

TARGET=($(curl -s http://wpp.isd.dp.ua/irls-reader-artifacts/targets.json | awk -F '"|"' '{print $4}' | sed '/^$/d' | sed '1d'))
BRANCH="develop"
ENVIRONMENT=(current stage)
REMOTE_LOGS_PATH="/opt/dev01-logs/reader"
REMOTE_LOGSTASH_CONF_DIR="/opt/logstash/conf"
REMOTE_KIBANA_DASHBOARD_PATH="/usr/share/kibana3/app/dashboards"
SSH_USER="root"
SSH_HOST="dev02.design.isd.dp.ua"


# check exists of config directory $REMOTE_LOGSTASH_CONF_DIR
ssh $SSH_USER@$SSH_HOST "if [ ! -d $REMOTE_LOGSTASH_CONF_DIR ]; then mkdir -p $REMOTE_LOGSTASH_CONF_DIR; fi"

for environment in "${ENVIRONMENT[@]}"
do
        if [ "$environment" == "current" ];
        then
                ART_DIR="/home/jenkins/irls-reader-artifacts"
        elif [ "$environment" == "stage" ];
        then
                ART_DIR="/home/jenkins/irls-reader-artifacts-stage"
        fi
        for target in "${TARGET[@]}"
        do

                MASK="$environment-reader-$target-$BRANCH"
                PID_OF_NODE=$(ps aux | grep node.*_"$target"_"$BRANCH"_"$environment" | grep -v grep | awk '{print $2}')
                if [ -z $PID_OF_NODE ]; then continue; fi
                PORT_OF_NODE=$(netstat -nlpt | grep "$PID_OF_NODE/node" | awk '{print $4}' | awk -F ':' '{print $2}')
                PORT_OF_APACHE=$(grep $PORT_OF_NODE /etc/apache2/sites-enabled/irls-$MASK | awk '{print $3}' | sort | uniq | awk -F ":" '{print $3}' | sed 's@\/@@g')

                if [ $PORT_OF_NODE = $PORT_OF_APACHE ]; then
                        DIR_NAME=$(grep artifacts /etc/apache2/sites-enabled/irls-$MASK | awk '{print $3}' | sort | uniq | awk -F '/' '{print $5}')
                        LOCAL_LOGS_PATH="$ART_DIR/$DIR_NAME/packages"
                        REMOTE_LOGS_PATH_ENV="$REMOTE_LOGS_PATH/$environment/$target/$DIR_NAME"
                        ssh $SSH_USER@$SSH_HOST "if [ ! -d $REMOTE_LOGS_PATH_ENV ]; then mkdir -p $REMOTE_LOGS_PATH_ENV; fi"
                        cd $LOCAL_LOGS_PATH
                        LIST=($(ls reader.trace* 2>/dev/null))
                        if [ -z $LIST ]; then continue; fi
                        for log in ${LIST[@]}
                        do
                                #echo processing $log
                                MD5SUM_LOCAL=$(md5sum $log | awk '{ print $1 }')
                                #echo MD5SUM_LOCAL is $MD5SUM_LOCAL
                                MD5SUM_REMOTE=$(ssh $SSH_USER@$SSH_HOST "if [ -f "$REMOTE_LOGS_PATH_ENV"/"$log" ]; then md5sum "$REMOTE_LOGS_PATH_ENV"/"$log" | awk '{print \$1}'; fi")
                                #echo MD5SUM_REMOTE is $MD5SUM_REMOTE
                                if [ -z $MD5SUM_REMOTE ] || ! [ $MD5SUM_LOCAL = $MD5SUM_REMOTE ]; then
                                        scp $LOCAL_LOGS_PATH/$log $SSH_USER@$SSH_HOST:$REMOTE_LOGS_PATH_ENV/
                                fi
                        done
                fi
                # it contents of the configuration file, depending from the target, environment and branch name
                CONF_FILE="$MASK.conf"
                ssh $SSH_USER@$SSH_HOST "
                        cd $REMOTE_LOGSTASH_CONF_DIR
                        if [ ! -f $CONF_FILE ]; then
                        echo -e 'input {\n\tfile {\n\t\ttype => \"$MASK\"\n\t\tpath => \"$REMOTE_LOGS_PATH/$environment/$target/*/reader.trace*\"\n\t\tstart_position => \"beginning\"\n\t\tstat_interval => 5\n\t}\n}\nfilter {\n\tif [type] == \"$MASK\" {\n\t\tgrok {\n\t\t\tbreak_on_match => false\n\t\t\tmatch=> [\n\t\t\t\t\"message\", \"%{NODECLIENTLOG1}\",\n\t\t\t\t\"message\", \"%{NODECLIENTLOG2}\",\n\t\t\t\t\"message\", \"%{NODESERVERLOG1}\",\n\t\t\t\t\"message\", \"%{NODESERVERLOG2}\"\n\t\t\t]\n\t\t}\n\t\tmultiline {\n\t\t\tpattern => \"^    at \"\n\t\t\twhat => \"previous\"\n\t\t}\n\t\tdate {\n\t\t\tlocale => \"en\"\n\t\t\tmatch => [\"node_timestamp\", \"YYYY-MM-dd HH:mm:ss.SSS\"]\n\t\t\ttimezone => \"UTC\"\n\t\t\ttarget => \"@timestamp\"\n\t\t}\n\t\tmutate {\n\t\t\tremove_field => [ \"node_timestamp\" ]\n\t\t}\n\t}\n}\noutput {\n\tif [type] == \"$MASK\" {\n\t\telasticsearch {\n\t\t\thost => \"127.0.0.1\"\n\t\t\tindex => \"$MASK-index\"\n\t\t\tindex_type => \"$MASK\"\n\t\t}\n\t}\n}' > $CONF_FILE
                        PID_LOGSTASH=\$(ps aux | grep logstash.*conf | grep -v grep | awk '{print \$2}')
                        if [ ! -z \$PID_LOGSTASH ]; then
                                kill -9 \$PID_LOGSTASH
                                /opt/logstash/bin/logstash -f /opt/logstash/conf > /dev/null 2>&1 &
                        fi
                fi"
                # it creates dashboard file
                DASHBOARD_FILE=$REMOTE_KIBANA_DASHBOARD_PATH/"$MASK"_logs.json
                ssh $SSH_USER@$SSH_HOST "if [ ! -f $DASHBOARD_FILE ]; then echo -e '{\n\t\"title\": \"reader $environment $target develop logs\",\n\t\"services\": {\n\t\t\"query\": {\n\t\t\t\"list\": {\n\t\t\t\t\"0\": {\n\t\t\t\t\t\"query\": \"*\",\n\t\t\t\t\t\"alias\": \"\",\n\t\t\t\t\t\"color\": \"#7EB26D\",\n\t\t\t\t\t\"id\": 0,\n\t\t\t\t\t\"pin\": false,\n\t\t\t\t\t\"type\": \"lucene\",\n\t\t\t\t\t\"enable\": true\n\t\t\t\t}\n\t\t\t},\n\t\t\t\"ids\": [\n\t\t\t\t0\n\t\t\t]\n\t\t},\n\t\t\"filter\": {\n\t\t\t\"list\": {},\n\t\t\t\"ids\": []\n\t\t}\n\t},\n\t\"rows\": [\n\t\t{\n\t\t\t\"title\": \"client IDs\",\n\t\t\t\"height\": \"150px\",\n\t\t\t\"editable\": true,\n\t\t\t\"collapse\": false,\n\t\t\t\"collapsable\": true,\n\t\t\t\"panels\": [\n\t\t\t\t{\n\t\t\t\t\t\"error\": false,\n\t\t\t\t\t\"span\": 12,\n\t\t\t\t\t\"editable\": true,\n\t\t\t\t\t\"type\": \"terms\",\n\t\t\t\t\t\"loadingEditor\": false,\n\t\t\t\t\t\"field\": \"node_client_id\",\n\t\t\t\t\t\"exclude\": [],\n\t\t\t\t\t\"missing\": true,\n\t\t\t\t\t\"other\": true,\n\t\t\t\t\t\"size\": 10,\n\t\t\t\t\t\"order\": \"count\",\n\t\t\t\t\t\"style\": {\n\t\t\t\t\t\t\"font-size\": \"10pt\"\n\t\t\t\t\t},\n\t\t\t\t\t\"donut\": false,\n\t\t\t\t\t\"tilt\": false,\n\t\t\t\t\t\"labels\": true,\n\t\t\t\t\t\"arrangement\": \"horizontal\",\n\t\t\t\t\t\"chart\": \"bar\",\n\t\t\t\t\t\"counter_pos\": \"above\",\n\t\t\t\t\t\"spyable\": true,\n\t\t\t\t\t\"queries\": {\n\t\t\t\t\t\t\"mode\": \"all\",\n\t\t\t\t\t\t\"ids\": [\n\t\t\t\t\t\t\t0\n\t\t\t\t\t\t]\n\t\t\t\t\t},\n\t\t\t\t\t\"tmode\": \"terms\",\n\t\t\t\t\t\"tstat\": \"total\",\n\t\t\t\t\t\"valuefield\": \"\",\n\t\t\t\t\t\"title\": \"node_client_id\"\n\t\t\t\t}\n\t\t\t],\n\t\t\t\"notice\": false\n\t\t},\n\t\t{\n\t\t\t\"title\": \"time statistics\",\n\t\t\t\"height\": \"150px\",\n\t\t\t\"editable\": true,\n\t\t\t\"collapse\": false,\n\t\t\t\"collapsable\": true,\n\t\t\t\"panels\": [\n\t\t\t\t{\n\t\t\t\t\t\"error\": false,\n\t\t\t\t\t\"span\": 6,\n\t\t\t\t\t\"editable\": true,\n\t\t\t\t\t\"type\": \"terms\",\n\t\t\t\t\t\"loadingEditor\": false,\n\t\t\t\t\t\"field\": \"node_loglevel\",\n\t\t\t\t\t\"exclude\": [],\n\t\t\t\t\t\"missing\": true,\n\t\t\t\t\t\"other\": true,\n\t\t\t\t\t\"size\": 10,\n\t\t\t\t\t\"order\": \"count\",\n\t\t\t\t\t\"style\": {\n\t\t\t\t\t\t\"font-size\": \"10pt\"\n\t\t\t\t\t},\n\t\t\t\t\t\"donut\": false,\n\t\t\t\t\t\"tilt\": false,\n\t\t\t\t\t\"labels\": true,\n\t\t\t\t\t\"arrangement\": \"horizontal\",\n\t\t\t\t\t\"chart\": \"bar\",\n\t\t\t\t\t\"counter_pos\": \"above\",\n\t\t\t\t\t\"spyable\": true,\n\t\t\t\t\t\"queries\": {\n\t\t\t\t\t\t\"mode\": \"all\",\n\t\t\t\t\t\t\"ids\": [\n\t\t\t\t\t\t\t0\n\t\t\t\t\t\t]\n\t\t\t\t\t},\n\t\t\t\t\t\"tmode\": \"terms\",\n\t\t\t\t\t\"tstat\": \"total\",\n\t\t\t\t\t\"valuefield\": \"\",\n\t\t\t\t\t\"title\": \"node_loglevel\"\n\t\t\t\t},\n\t\t\t\t{\n\t\t\t\t\t\"error\": false,\n\t\t\t\t\t\"span\": 6,\n\t\t\t\t\t\"editable\": true,\n\t\t\t\t\t\"type\": \"terms\",\n\t\t\t\t\t\"loadingEditor\": false,\n\t\t\t\t\t\"field\": \"node_client_request\",\n\t\t\t\t\t\"exclude\": [],\n\t\t\t\t\t\"missing\": true,\n\t\t\t\t\t\"other\": true,\n\t\t\t\t\t\"size\": 10,\n\t\t\t\t\t\"order\": \"count\",\n\t\t\t\t\t\"style\": {\n\t\t\t\t\t\t\"font-size\": \"10pt\"\n\t\t\t\t\t},\n\t\t\t\t\t\"donut\": false,\n\t\t\t\t\t\"tilt\": false,\n\t\t\t\t\t\"labels\": true,\n\t\t\t\t\t\"arrangement\": \"horizontal\",\n\t\t\t\t\t\"chart\": \"bar\",\n\t\t\t\t\t\"counter_pos\": \"above\",\n\t\t\t\t\t\"spyable\": true,\n\t\t\t\t\t\"queries\": {\n\t\t\t\t\t\t\"mode\": \"all\",\n\t\t\t\t\t\t\"ids\": [\n\t\t\t\t\t\t\t0\n\t\t\t\t\t\t]\n\t\t\t\t\t},\n\t\t\t\t\t\"tmode\": \"terms\",\n\t\t\t\t\t\"tstat\": \"total\",\n\t\t\t\t\t\"valuefield\": \"\",\n\t\t\t\t\t\"title\": \"node_client_request\"\n\t\t\t\t}\n\t\t\t],\n\t\t\t\"notice\": false\n\t\t},\n\t\t{\n\t\t\t\"title\": \"table\",\n\t\t\t\"height\": \"150px\",\n\t\t\t\"editable\": true,\n\t\t\t\"collapse\": false,\n\t\t\t\"collapsable\": true,\n\t\t\t\"panels\": [\n\t\t\t\t{\n\t\t\t\t\t\"error\": false,\n\t\t\t\t\t\"span\": 12,\n\t\t\t\t\t\"editable\": true,\n\t\t\t\t\t\"type\": \"table\",\n\t\t\t\t\t\"loadingEditor\": false,\n\t\t\t\t\t\"size\": 100,\n\t\t\t\t\t\"pages\": 5,\n\t\t\t\t\t\"offset\": 100,\n\t\t\t\t\t\"sort\": [\n\t\t\t\t\t\t\"@timestamp\",\n\t\t\t\t\t\t\"desc\"\n\t\t\t\t\t],\n\t\t\t\t\t\"overflow\": \"min-height\",\n\t\t\t\t\t\"fields\": [\n\t\t\t\t\t\t\"@timestamp\",\n\t\t\t\t\t\t\"node_loglevel\",\n\t\t\t\t\t\t\"node_client_id\",\n\t\t\t\t\t\t\"node_client_ip1\",\n\t\t\t\t\t\t\"node_client_ip2\",\n\t\t\t\t\t\t\"node_client_request\",\n\t\t\t\t\t\t\"node_message\"\n\t\t\t\t\t],\n\t\t\t\t\t\"highlight\": [\n\t\t\t\t\t\t\"node_loglevel\"\n\t\t\t\t\t],\n\t\t\t\t\t\"sortable\": true,\n\t\t\t\t\t\"header\": true,\n\t\t\t\t\t\"paging\": true,\n\t\t\t\t\t\"field_list\": true,\n\t\t\t\t\t\"all_fields\": false,\n\t\t\t\t\t\"trimFactor\": 300,\n\t\t\t\t\t\"localTime\": false,\n\t\t\t\t\t\"timeField\": \"@timestamp\",\n\t\t\t\t\t\"spyable\": true,\n\t\t\t\t\t\"queries\": {\n\t\t\t\t\t\t\"mode\": \"all\",\n\t\t\t\t\t\t\"ids\": [\n\t\t\t\t\t\t\t0\n\t\t\t\t\t\t]\n\t\t\t\t\t},\n\t\t\t\t\t\"style\": {\n\t\t\t\t\t\t\"font-size\": \"9pt\"\n\t\t\t\t\t},\n\t\t\t\t\t\"normTimes\": true,\n\t\t\t\t\t\"title\": \"custom fields\"\n\t\t\t\t}\n\t\t\t],\n\t\t\t\"notice\": false\n\t\t}\n\t],\n\t\"editable\": true,\n\t\"failover\": false,\n\t\"index\": {\n\t\t\"interval\": \"none\",\n\t\t\"pattern\": \"[logstash-]YYYY.MM.DD\",\n\t\t\"default\": \"$MASK-index\",\n\t\t\"warm_fields\": false\n\t},\n\t\"style\": \"dark\",\n\t\"panel_hints\": true,\n\t\"pulldowns\": [\n\t\t{\n\t\t\t\"type\": \"query\",\n\t\t\t\"collapse\": true,\n\t\t\t\"notice\": false,\n\t\t\t\"enable\": true,\n\t\t\t\"query\": \"*\",\n\t\t\t\"pinned\": true,\n\t\t\t\"history\": [],\n\t\t\t\"remember\": 10\n\t\t},\n\t\t{\n\t\t\t\"type\": \"filtering\",\n\t\t\t\"collapse\": false,\n\t\t\t\"notice\": true,\n\t\t\t\"enable\": true\n\t\t}\n\t],\n\t\"nav\": [\n\t\t{\n\t\t\t\"type\": \"timepicker\",\n\t\t\t\"collapse\": false,\n\t\t\t\"notice\": false,\n\t\t\t\"enable\": true,\n\t\t\t\"status\": \"Stable\",\n\t\t\t\"time_options\": [\n\t\t\t\t\"5m\",\n\t\t\t\t\"15m\",\n\t\t\t\t\"1h\",\n\t\t\t\t\"6h\",\n\t\t\t\t\"12h\",\n\t\t\t\t\"24h\",\n\t\t\t\t\"2d\",\n\t\t\t\t\"7d\",\n\t\t\t\t\"30d\"\n\t\t\t],\n\t\t\t\"refresh_intervals\": [\n\t\t\t\t\"5s\",\n\t\t\t\t\"10s\",\n\t\t\t\t\"30s\",\n\t\t\t\t\"1m\",\n\t\t\t\t\"5m\",\n\t\t\t\t\"15m\",\n\t\t\t\t\"30m\",\n\t\t\t\t\"1h\",\n\t\t\t\t\"2h\",\n\t\t\t\t\"1d\"\n\t\t\t],\n\t\t\t\"timefield\": \"@timestamp\"\n\t\t}\n\t],\n\t\"loader\": {\n\t\t\"save_gist\": false,\n\t\t\"save_elasticsearch\": true,\n\t\t\"save_local\": true,\n\t\t\"save_default\": true,\n\t\t\"save_temp\": true,\n\t\t\"save_temp_ttl_enable\": true,\n\t\t\"save_temp_ttl\": \"30d\",\n\t\t\"load_gist\": false,\n\t\t\"load_elasticsearch\": true,\n\t\t\"load_elasticsearch_size\": 20,\n\t\t\"load_local\": false,\n\t\t\"hide\": false\n\t},\n\t\"refresh\": false\n}' > $DASHBOARD_FILE; fi"
                # update link from default page
                ssh $SSH_USER@$SSH_HOST "
                        # number of line contains $environment links
                        N=\$(grep title.*$environment $REMOTE_KIBANA_DASHBOARD_PATH/default.json -B3 -n | grep content | awk -F '-' '{print \$1}')
                        CURRENT_LINE=\$(sed -n \"\$N\"p $REMOTE_KIBANA_DASHBOARD_PATH/default.json | awk -F'\"|\"' '{print \$4}' | sed -e 's@\\\@\\\\\\\\\\\\@g' -e 's@\[@\\\[@g' -e 's@\]@\\\]@g')
                        ! [[ \$(sed -n \"\$N\"p $REMOTE_KIBANA_DASHBOARD_PATH/default.json | grep '$target ($BRANCH)') ]] && eval sed -i \$N\\\"s@\$CURRENT_LINE@\$CURRENT_LINE'\''\''\'n'\''\''\'n\[$target \($BRANCH\)\]\(#/dashboard/file/'$MASK'_logs.json\)@\\\" $REMOTE_KIBANA_DASHBOARD_PATH/default.json"

        done
done
