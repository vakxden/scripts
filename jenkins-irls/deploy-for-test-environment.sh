###
### Checking variables that were passed to the current bash-script
###
if [ -z $BRANCHNAME ]; then
    printf "[ERROR_BRANCHNAME] branchname must be passed! \n"
    exit 1
fi

#frome node
export NODE_HOME=/opt/node
export PATH=$PATH:$NODE_HOME/bin
# from phantom
export NODE_PATH=/opt/node/lib/node_modules/

###
### Constant local variables
###
BRANCH=$(echo $BRANCHNAME | sed 's/\//-/g' | sed 's/_/-/g')
BUILD_ID=donotkillme
CURRENT_ART_PATH=$HOME/irls-reader-artifacts
TARGET=($(echo $TARGET))

# clean file myenv
cat /dev/null > $WORKSPACE/myenv

###
### Create associative array
###
deploymentPackageId=($(echo $ID))
declare -A combineArray

for ((i=0; i<${#deploymentPackageId[@]}; i++))
do
        a=$(echo "${deploymentPackageId[i]}"| cut -d"_" -f 2-)
        combineArray+=(["$a"]="${deploymentPackageId[i]}")
done

###
### Functions
###
function generate_files {
        # $1 = $PKG_DIR ( or STAGE_PKG_DIR from STAGE-env )
        cd $1
        sudo $HOME/scripts/portgenerator-for-deploy.sh $BRANCH $i ${combineArray[$i]}
        #rm -f $1/server/config/local.json
        rm -f $1/config/local.json
        #cp -f local.json $1/server/config/
        cp -f local.json $1/config/
        ls -lah
        echo PWD=$PWD
}

function pid_node {
        # $1 = $2 (server/$INDEX_FILE) from function start_node = $INDEX_FILE
        ### Starting (or restarting) node server
                PID=$(ps aux | grep "node $1" | grep -v grep | /usr/bin/awk '{print $2}')
                if [ ! -z "$PID" ];then
                        kill -9 $PID
                        #nohup node $1 > /dev/null 2>&1 &
                        if [ -f nohup.out ]; then cat /dev/null > nohup.out; fi
                        nohup node $1 >> nohup.out 2>&1 &
                else
                        #nohup node $1 > /dev/null 2>&1 &
                        if [ -f nohup.out ]; then cat /dev/null > nohup.out; fi
                        nohup node $1 >> nohup.out 2>&1 &
                fi
}

function start_node {
        # if content for running nodejs-server exists?
        # $1=$PKG_DIR ( or STAGE_PKG_DIR from STAGE-env )
        # $2=$INDEX_FILE
        if [ -d $1/server/config ]; then
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
for i in "${!combineArray[@]}"
do
        # variables
        PKG_DIR=$CURRENT_ART_PATH/${combineArray[$i]}/packages
        INDEX_FILE='index_'$i'_'$BRANCH'.js'
        # output value for a pair "key-value"
        echo $i --- ${combineArray[$i]}
        # generate index.html and file local.config.json ( old name - "local.json")
        generate_files $PKG_DIR
        # init users database
        cd $PKG_DIR
        if [ -f server/init.js ]; then
                node server/init.js
        fi
        # run (re-run) node
        start_node $PKG_DIR $INDEX_FILE
        # generate links for description job
        echo admin-link-$i="http://irls-autotests.design.isd.dp.ua/irls/test/reader/$i/$BRANCH/admin/dist/app/index_admin.html" >> $WORKSPACE/myenv
        echo editor-link-$i="http://irls-autotests.design.isd.dp.ua/irls/test/reader/$i/$BRANCH/editor/dist/app/index_editor.html" >> $WORKSPACE/myenv
        echo reader-link-$i="http://irls-autotests.design.isd.dp.ua/irls/test/reader/$i/$BRANCH/reader/dist/app/index_reader.html" >> $WORKSPACE/myenv
        echo portal-link-$i="http://irls-autotests.design.isd.dp.ua/irls/test/reader/$i/$BRANCH/portal/dist/app/index_portal.html" >> $WORKSPACE/myenv
done
