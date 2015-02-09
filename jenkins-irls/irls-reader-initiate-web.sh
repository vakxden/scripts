### Variables
ARTIFACTS_DIR=$HOME/irls-reader-artifacts
if [ "$BRANCHNAME" != "master" ]; then
        CURRENT_EPUBS=$HOME/irls-reader-current-epubs/develop
else
        CURRENT_EPUBS=$HOME/irls-reader-current-epubs/$BRANCHNAME
fi
TARGET=($(echo $TARGET))
PREFIX=$(echo $BRANCHNAME | sed 's/\//-/g')

### Create associative array
deploymentPackageId=($(echo $ID))
printf "Array deploymentPackageId contain nexts elements:\n"
printf '%s\n' "${deploymentPackageId[@]}"

declare -A combineArray
for ((x=0; x<${#deploymentPackageId[@]}; x++))
do
        a=$(echo "${deploymentPackageId[x]}"| cut -d"_" -f 2-)
        combineArray+=(["$a"]="${deploymentPackageId[x]}")
done

printf "Associative array combineArray contains next key-value elements:\n"
for k in "${!combineArray[@]}"
do
        printf '%s\n' "key:$k -- value:${combineArray[$k]}"
done

### Create web-version of application
function main_loop {
        notmainloop ()
        {
                # createing of web-package
                cd $WORKSPACE/packager
		if [ $BRANCHNAME == "master" ];
		then
                	time node index.js --platform=web --config=$WORKSPACE/targets --from=$WORKSPACE/client --manifest=$WORKSPACE/client/package.json --prefix=$PREFIX- --epubs=$CURRENT_EPUBS
		else
                	#time node index.js --platform=web --config=$WORKSPACE/targets --from=$WORKSPACE/client --manifest=$WORKSPACE/client/package.json --prefix=$PREFIX- --epubs=$CURRENT_EPUBS --buildnumber=$BUILD_NUMBER --builddate="$BUILD_DATE"
                	time node index.js --platform=web --config=$WORKSPACE/targets --from=$WORKSPACE/client --manifest=$WORKSPACE/package.json --prefix=$PREFIX- --epubs=$CURRENT_EPUBS --buildnumber=$BUILD_NUMBER --builddate="$BUILD_DATE"
		fi
                cd $WORKSPACE
                # move of web-package to artifacts directory (for current environment)
                if [ ! -d $ARTIFACTS_DIR/${combineArray[$i]}/packages ]; then
                        mkdir -p $ARTIFACTS_DIR/${combineArray[$i]}/packages
                fi
                time rsync -r --delete --exclude "tests" --exclude "packager" --exclude "targets" --exclude "myenv" --exclude "Gruntfile.js" --exclude "artifacts" $WORKSPACE/ $ARTIFACTS_DIR/${combineArray[$i]}/packages/
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
