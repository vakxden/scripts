### Variables
ARTIFACTS_DIR=$HOME/irls-reader-artifacts
if [ "$BRANCHNAME" != "master" ]; then
        CURRENT_EPUBS=$HOME/irls-reader-current-epubs/develop
else
        CURRENT_EPUBS=$HOME/irls-reader-current-epubs/$BRANCHNAME
fi
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
                cd $WORKSPACE/packager
                time node index.js --platform=web --config=$WORKSPACE/targets --from=$WORKSPACE/client --manifest=$WORKSPACE/client/package.json --prefix=$PREFIX- --epubs=$CURRENT_EPUBS
                #create index
                cd $WORKSPACE
                if [ ! -d $ARTIFACTS_DIR/${combineArray[$i]}/packages ]; then
                        mkdir -p $ARTIFACTS_DIR/${combineArray[$i]}/packages
                fi
		time rsync -rzv --delete --exclude "tests" --exclude "packager" --exclude "targets" --exclude "myenv" --exclude "Gruntfile.js" $WORKSPACE/ $ARTIFACTS_DIR/${combineArray[$i]}/packages/
                if [ ! -d $ARTIFACTS_DIR/${combineArray[$i]}/packages/client ]; then
                        mkdir -p $ARTIFACTS_DIR/${combineArray[$i]}/packages/client
		else
			rm -rf $ARTIFACTS_DIR/${combineArray[$i]}/packages/client/*
                fi
                cp -Rf $WORKSPACE/packager/out/dest/*/* $ARTIFACTS_DIR/${combineArray[$i]}/packages/client/
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
