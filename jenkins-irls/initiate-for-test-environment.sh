#frome node
export NODE_HOME=/opt/node
export PATH=$PATH:$NODE_HOME/bin
# from phantom
export NODE_PATH=/opt/node/lib/node_modules/

### Variables
ARTIFACTS_DIR=$HOME/irls-reader-artifacts
CURRENT_EPUBS=$HOME/irls-reader-current-epubs
TARGET=($(echo $TARGET))
PREFIX=$(echo $BRANCHNAME | sed 's/\//-/g')
deploymentPackageId=($(echo $ID))
declare -A combineArray

### Create associative array
for ((i=0; i<${#deploymentPackageId[@]}; i++))
do
        a=$(echo "${deploymentPackageId[i]}"| cut -d"_" -f 2-)
        combineArray+=(["$a"]="${deploymentPackageId[i]}")
done
### Create web-version of application
function main_loop {
        notmainloop ()
        {
                if [ ! -d $WORKSPACE/build/build ]; then mkdir -p $WORKSPACE/build/build; fi
                cp -Rf ~/build_re/$BRANCHNAME/phonegap-plugins $WORKSPACE/build/build
                cd $WORKSPACE/build
                echo "{}" > $WORKSPACE/build/meta.json
                time node index.js --platform=web --workspace=$WORKSPACE --prefix=$PREFIX- --epubs=$CURRENT_EPUBS --buildnumber=$BUILD_NUMBER --builddate="$BUILD_ID"
                #create index
                cd $WORKSPACE
                if [ ! -d $ARTIFACTS_DIR/${combineArray[$i]}/packages ]; then
                        mkdir -p $ARTIFACTS_DIR/${combineArray[$i]}/packages
                fi
		time rsync -lr --exclude "tests" --exclude "targets" --exclude "build/node_modules" $WORKSPACE/ $ARTIFACTS_DIR/${combineArray[$i]}/packages/
                if [ ! -d $ARTIFACTS_DIR/${combineArray[$i]}/packages/client ]; then
                        mkdir -p $ARTIFACTS_DIR/${combineArray[$i]}/packages/client
                else
                        rm -rf $ARTIFACTS_DIR/${combineArray[$i]}/packages/client/*
                fi
        }
        for i in "${!combineArray[@]}"
        do

                rm -rf $WORKSPACE/*
                GIT_COMMIT_TARGET=$(echo "$GIT_COMMIT"-"$i")
                cp -Rf $CURRENT_BUILD/$GIT_COMMIT_TARGET/* $WORKSPACE/

                echo $i --- ${combineArray[$i]}
                ### Checking contain platform
                if grep "platforms.*web" $WORKSPACE/targets/$i/targetConfig.json; then
                        notmainloop
                else
                        echo "Shutdown of this job because platform \"web\" not found in config targetConfig.json"
                        exit 0
                fi
        done
}

main_loop
