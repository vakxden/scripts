###
### Variables
###
export NO_PROXY="127.0.0.1, 10.98.244.26, localhost, *.loc"
export FTP_PROXY="http://10.98.192.120:3128"
export HTTPS_PROXY="http://10.98.192.120:3128"
export https_proxy="http://10.98.192.120:3128"
export HTTP_PROXY="http://10.98.192.120:3128"
export http_proxy="http://10.98.192.120:3128"
export NODE_HOME=/opt/node
export ANDROID_HOME=/opt/android-sdk-linux
export PATH=$PATH:$NODE_HOME/bin:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools:$JAVA_HOME/bin
BRANCH=$(echo $READER_BRANCH_NAME | sed 's/\//-/g' | sed 's/_/-/g')
NIGHTLY_ARTIFACTS_DIR="/home/jenkins/irls-reader-artifacts-nightly"
CURRENT_EPUBS=$HOME/irls-reader-current-epubs
FACETS=($(echo $FACET))

### Create associative array
deploymentPackageId=($(echo $ID))
declare -A combineArray
for ((x=0; x<${#deploymentPackageId[@]}; x++))
do
        for ((y=0; y<${#FACETS[@]}; y++))
        do
                if [ -n "$(echo "${deploymentPackageId[x]}" | grep "${FACETS[y]}$")" ]; then
                        combineArray+=(["${FACETS[y]}"]="${deploymentPackageId[x]}")
                fi
        done
done

###
### Body (working with all facets exclude "ocean")
###

### Main loop
function main_loop {
        notmainloop ()
        {
        if [ $(echo "$i" | egrep "ocean$") ]; then
                getAbort()
                {
                        printf "we do not create the apk-file for facet named 'ocean'\n"
                }
                getAbort
                trap 'getAbort; exit' SIGTERM
        else
                # Create apk-file
                cd $WORKSPACE/packager
                time node index.js --platform=android --config=$WORKSPACE/targets --from=$WORKSPACE/client --manifest=$WORKSPACE/client/package.json --prefix=$BRANCH- --epubs=$CURRENT_EPUBS
                rm -f out/dest/platforms/android/ant-build/*$i*unaligned.apk
                mv $WORKSPACE/packager/out/dest/platforms/android/ant-build/*$i*.apk $WORKSPACE/$BRANCH-FFA_Reader-$i.apk
                ssh jenkins@dev01.isd.dp.ua "
                if [ ! -d $NIGHTLY_ARTIFACTS_DIR/${combineArray[$i]}/packages/artifacts ]; then
                        mkdir -p $NIGHTLY_ARTIFACTS_DIR/${combineArray[$i]}/packages/artifacts
                fi
                "
                time scp $WORKSPACE/$BRANCH-FFA_Reader-$i.apk  jenkins@dev01.isd.dp.ua:$NIGHTLY_ARTIFACTS_DIR/${combineArray[$i]}/packages/artifacts/ && rm -f $WORKSPACE/$BRANCH-FFA_Reader-$i.apk
        fi
        }

        for i in "${!combineArray[@]}"
        do
                rm -rf $WORKSPACE/*
                GIT_COMMIT_TARGET=$(echo "$READER_COMMIT_HASH"-"$i"_"FFA")
                cp -Rf $NIGHTLY_BUILD/$GIT_COMMIT_TARGET/* $WORKSPACE/


                echo $i --- ${combineArray[$i]}
                ### Checking
                if [ "$READER_BRANCH_NAME" = "feature/platforms-config" ]; then
                        if grep "platforms.*android" $WORKSPACE/targets/"$i"_"FFA"/targetConfig.json; then
                                notmainloop
                        else
                                echo "Shutdown of this job because platform \"android\" not found in config targetConfig.json"
                                exit 0
                        fi
                else
                        notmainloop
                fi
        done
}

main_loop