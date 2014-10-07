### This job should take such variables as NIGHTLY_ARTIFACTS_DIR, ENVIRONMENT, READER_BRANCH_NAME, ID, TARGET 

###
### Constant local variables
###
BRANCH=$(echo $READER_BRANCH_NAME | sed 's/\//-/g' | sed 's/_/-/g')
BUILD_ID=donotkillme
TARGET=($(echo $TARGET))
###
### Create associative array
###
deploymentPackageId=($(echo $ID))
declare -A combineArray

for ((i=0; i<${#deploymentPackageId[@]}; i++))
do
        for ((y=0; y<${#TARGET[@]}; y++))
        do
                if [ -n "$(echo "${deploymentPackageId[i]}" | grep "${TARGET[y]}$")" ]; then
                        combineArray+=(["${TARGET[y]}"]="${deploymentPackageId[i]}")
                fi
        done
done
###
### Functions
###
function generate_files {
        cd $1
        sudo /home/jenkins/scripts/portgenerator-for-deploy.sh $BRANCH $i $ENVIRONMENT ${combineArray[$i]}
        #rm -f $1/server/config/local.json
        ls -lah
        echo PWD=$PWD
}
function pid_node {
        # $1 = $2 (server/$INDEX_FILE) from function start_node = $INDEX_FILE
        ### Starting (or restarting) node server
                PID=$(ps aux | grep "node $1" | grep -v grep | /usr/bin/awk '{print $2}')
                if [ ! -z "$PID" ];then
                        kill -9 $PID
                        nohup node $1 > /dev/null 2>&1 &
                else
                        nohup node $1 > /dev/null 2>&1 &
                fi
                rm -f local.json irls-current-reader-* irls-stage-reader-*
}
function start_node {
        # if content for running nodejs-server exists?
        # $1=$PKG_DIR
        # $2=$INDEX_FILE
        if [ -d $1/server/config ]; then
                cp -f local.json $1/server/config/
                if [ ! -f $1/server/$2 ]; then
                        if [ -f $1/server/index.js ]; then
                                mv server/index.js server/$2
                                pid_node server/$2
                        elif [ -f $1/server/index_*.js ]; then
                                        cp $(ls -1 server/index*.js | head -1) server/$2
                                        pid_node server/$2
                        else
                                echo "not found server/index.js in $1" && exit 0
                        fi
                else
                        pid_node server/$2
                fi
        fi
}
###
### Body
###
if [ "$ENVIRONMENT" = "NIGHT" ]; then
        for i in "${!combineArray[@]}"
        do
                # variables
                PKG_DIR=$NIGHTLY_ARTIFACTS_DIR/${combineArray[$i]}/packages
                INDEX_FILE='index_'$i'_'$BRANCH'_'$ENVIRONMENT'.js'
                # output value for a pair "key-value"
                echo $i --- ${combineArray[$i]}
                # generate index.html and local.json
                generate_files $PKG_DIR
                # run (re-run) node
                start_node $PKG_DIR $INDEX_FILE
                # update environment.json file
                /home/jenkins/scripts/search_for_environment.sh "${combineArray[$i]}" "$ENVIRONMENT"
        done
else
        printf "[ERROR_DEST] ENVIRONMENT must be NIGHT! Not $ENVIRONMENT! \n"
        exit 1
fi
