###
### Variables
###
export NO_PROXY="127.0.0.1, 10.98.244.26, localhost, *.loc"
export FTP_PROXY="http://10.98.192.120:3128"
export HTTPS_PROXY="http://10.98.192.120:3128"
export https_proxy="http://10.98.192.120:3128"
export HTTP_PROXY="http://10.98.192.120:3128"
export http_proxy="http://10.98.192.120:3128"
###
### export NODE_HOME=/opt/node
### export ANDROID_HOME=/opt/android-sdk-linux
### export PATH=$PATH:$NODE_HOME/bin:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools:$JAVA_HOME/bin
###
export NODE_HOME=/opt/node
export CORDOVA_ARM=/home/jenkins/crosswalk_environment/crosswalk-cordova-11.40.277.7-arm
export PATH=/home/jenkins/crosswalk_environment/ant/bin:/home/jenkins/crosswalk_environment/jdk1.7.0_76/bin:$NODE_HOME/bin:$PATH
export JAVA_HOME=/home/jenkins/crosswalk_environment/jdk1.7.0_76
export PATH=/home/jenkins/crosswalk_environment/android-sdk-linux:$PATH
export PATH=/home/jenkins/crosswalk_environment/android-sdk-linux/tools:$PATH
export PATH=/home/jenkins/crosswalk_environment/android-sdk-linux/platform-tools:$PATH

BRANCH=$(echo $BRANCHNAME | sed 's/\//-/g' | sed 's/_/-/g')
ARTIFACTS_DIR=/home/jenkins/irls-reader-artifacts
TARGETS_REPONAME="targets"
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
### Body of script
###

### Main loop
function main_loop {
        notmainloop ()
        {
                if [ ! -d $WORKSPACE/build/build ]; then mkdir -p $WORKSPACE/build/build; fi
                cp -Rf ~/build_re/$BRANCHNAME/phonegap-plugins $WORKSPACE/build/build/
                cp -Rf ~/build_re/$BRANCHNAME/android $WORKSPACE/build/build/
                cd $WORKSPACE/build
                if [ $BRANCHNAME == "master" ];
                then
                        time node index.js --platform=android --config=$WORKSPACE/targets --from=$WORKSPACE/client --prefix=$BRANCH- --epubs=$CURRENT_EPUBS
                else
						$CORDOVA_ARM/bin/create $i org.crosswalkproject.$(echo $i | sed 's/-/_/g') $BRANCH
                        time node index.js --platform=android --config=$WORKSPACE/targets --from=$WORKSPACE/client --manifest=$WORKSPACE/client/package.json --prefix=$BRANCH- --epubs=$CURRENT_EPUBS --crosswalk=/home/jenkins/crosswalk_environment/crosswalk-11.40.277.7
						$WORKSPACE/build/$i/cordova/build
                fi
				### Determine of brand
				BRAND=$(grep brand $WORKSPACE/$TARGETS_REPONAME/$i/targetConfig.json | awk -F '"|"' '{print $4}')
				### Determine of apk name
				APK_NAME=$(echo $BRANCH-"$BRAND"_Reader-$i)
				APK_FILE_NAME="$APK_NAME.apk"
				### Copying builded apk to workspace
                cp $WORKSPACE/build/$i/out/*.apk $WORKSPACE/$APK_FILE_NAME
                ssh jenkins@dev01.isd.dp.ua "
                if [ ! -d $ARTIFACTS_DIR/${combineArray[$i]}/packages/artifacts ]; then
                        mkdir -p $ARTIFACTS_DIR/${combineArray[$i]}/packages/artifacts
                fi
                "
				### Copying builded apk to artifacts directory
                time scp $WORKSPACE/$APK_FILE_NAME  jenkins@dev01.isd.dp.ua:$ARTIFACTS_DIR/${combineArray[$i]}/packages/artifacts/ && rm -f $WORKSPACE/$BRANCH-$i.apk
        }

        for i in "${!combineArray[@]}"
        do
                rm -rf $WORKSPACE/*
                GIT_COMMIT_TARGET=$(echo "$GIT_COMMIT"-"$i")
                if [ ! -d $CURRENT_BUILD/$GIT_COMMIT_TARGET ]; then
                        echo "[ERROR_INITIATE] Directory  $CURRENT_BUILD/$GIT_COMMIT_TARGET not found! Maybe for this target ($i) disabled option platform:android ?"
                        exit 1
                else
                        cp -Rf $CURRENT_BUILD/$GIT_COMMIT_TARGET/* $WORKSPACE/
                        echo $i --- ${combineArray[$i]}
                        notmainloop
                fi
        done
}

main_loop
