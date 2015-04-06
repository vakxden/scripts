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
BRANCH=$(echo $BRANCHNAME | sed 's/\//-/g' | sed 's/_/-/g')
ARTIFACTS_DIR=/home/jenkins/irls-reader-artifacts
if [ ! -d $HOME/irls-reader-current-epubs/$BRANCHNAME ]; then
	CURRENT_EPUBS=$HOME/irls-reader-current-epubs/develop
else
	CURRENT_EPUBS=$HOME/irls-reader-current-epubs/$BRANCHNAME
fi
TARGET=($(echo $TARGET))

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
                rm -f out/dest/platforms/android/ant-build/*unaligned.apk
                mv $WORKSPACE/packager/out/dest/platforms/android/ant-build/*.apk $WORKSPACE/$BRANCH-$i.apk
                ssh jenkins@dev01.isd.dp.ua "
                if [ ! -d $ARTIFACTS_DIR/${combineArray[$i]}/packages/artifacts ]; then
                        mkdir -p $ARTIFACTS_DIR/${combineArray[$i]}/packages/artifacts
                fi
                "
                time scp $WORKSPACE/$BRANCH-$i.apk  jenkins@dev01.isd.dp.ua:$ARTIFACTS_DIR/${combineArray[$i]}/packages/artifacts/ && rm -f $WORKSPACE/$BRANCH-$i.apk
        fi
        }

        for i in "${!combineArray[@]}"
        do
                rm -rf $WORKSPACE/*
                GIT_COMMIT_TARGET=$(echo "$GIT_COMMIT"-"$i")
		if [ ! -d $CURRENT_BUILD/$GIT_COMMIT_TARGET ]; then
			echo "[ERROR_INITIATE] Directory not found! Maybe for this target ($i) disabled option platform:android."
			exit 1
		else
			cp -Rf $CURRENT_BUILD/$GIT_COMMIT_TARGET/* $WORKSPACE/
			echo $i --- ${combineArray[$i]}
			notmainloop
		fi
        done
}

main_loop
