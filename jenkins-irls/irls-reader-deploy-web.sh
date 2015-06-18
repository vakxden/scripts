sleep 1
# This script executes on the remote host named dev01.isd.dp.ua

###
### Checking variables that were passed to the current script
###
ARRAY_OF_ENVIRONMENTS=(current stage public) #an array that contains the correct names of environments
containsElement () {
        local e
        for e in "${@:2}"; do [[ "$e" == "$1" ]] && return 0; done
        return 1
        }
if ! $(containsElement "$ENVIRONMENT" "${ARRAY_OF_ENVIRONMENTS[@]}"); then printf "[ERROR_DEST] ENVIRONMENT must be current or stage or public! Not $ENVIRONMENT! \n" && exit 1; fi

if [ -z $BRANCHNAME ]; then printf "[ERROR_BRANCHNAME] Branchname must be passed \n" && exit 1; fi

if [ -z $mark ]; then printf "[ERROR_MARK] mark must be passed \n" && exit 1; fi

if [ "$mark" = "all" ] || [ "$mark" = "initiate-web" ]; then
        echo \[WARN_MARK\] branch name is \<b\>$BRANCHNAME\</b\>\<br\>ENVIRONMENT is \<b\>$ENVIRONMENT\</b\>\<br\>ID is \<b\>$ID\</b\>
elif ! [ "$mark"  = "all" ] || ! [ "$mark"  = "initiate-web" ]; then
        echo \[WARN_MARK\] just running on empty
        exit 0
fi

###
### Constant local variables
###
BRANCH=$(echo $BRANCHNAME | sed 's/\//-/g' | sed 's/_/-/g')
BUILD_ID=donotkillme
CURRENT_ART_PATH=/home/jenkins/irls-reader-artifacts
STAGE_ART_PATH=/home/jenkins/irls-reader-artifacts-stage
REMOTE_ART_PATH=/home/dvac/irls-reader-artifacts
LIVE_DIR=/home/jenkins/irls-reader-live
LIVE_LINKS_DIR=/home/jenkins/irls-reader-live-links
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
        printf '%s\n' "key: $k -- value: ${combineArray[$k]}"
done


###
### Functions
###
function generate_files {
        sudo /home/jenkins/scripts/portgenerator-for-deploy.sh $BRANCH $i $ENVIRONMENT ${combineArray[$i]}
}

function start_node {
        # $1=$PKG_DIR ( or STAGE_PKG_DIR from STAGE-env )
        # $2=$INDEX_FILE
        if [ ! -f $1/server/$2 ]; then
                if [ $ENVIRONMENT == current ]; then mv $1/server/index.js $1/server/$2
                elif [ $ENVIRONMENT == stage ]; then mv $1/server/index_*_current.js $1/server/$2
                fi
        fi
        PID=$(ps aux | grep "node server/$2" | grep -v grep | /usr/bin/awk '{print $2}')
        cd $1
        if [ ! -z "$PID" ];then
                kill -9 $PID
                if [ -f nohup.out ]; then cat /dev/null > nohup.out; fi
                nohup node server/$2 > nohup.out 2>&1 &
        else
                if [ -f nohup.out ]; then cat /dev/null > nohup.out; fi
                nohup node server/$2 > nohup.out 2>&1 &
        fi
}

###
### Body
###
for i in "${!combineArray[@]}"
do
        echo starting of main loop...
        ### Output value for a pair "key-value"
        printf '%s\n' "key: $i -- value: ${combineArray[$i]}"
        ### Temporary local variables
        # terms for different environments
        CURRENT_PKG_DIR=$CURRENT_ART_PATH/${combineArray[$i]}
        STAGE_PKG_DIR=$STAGE_ART_PATH/${combineArray[$i]}
        INDEX_FILE='index_'$i'_'$BRANCH'_'$ENVIRONMENT'.js'
        if [ $ENVIRONMENT == current ] || [ $ENVIRONMENT == stage ]; then
                BRAND_URL="https://wpps.isd.dp.ua/irls/$ENVIRONMENT/reader/$i/$BRANCH"
        elif [ $ENVIRONMENT == public ]; then
                BRAND_URL="https://irls.isd.dp.ua/$i/$BRANCH"
                if [ $BRANCHNAME == "master" ];
                then
                        BUILD_INFO_JSON="client/dist/app/build.config.json"
                else
                        BUILD_INFO_JSON="build/config/build.config.json"
                fi
                RSYNC_FACETS_DIR="/home/dvac/rsync_facets/$i"
                # variables for product versioning
                SPRINT=$(grep version $STAGE_PKG_DIR/packages/$BUILD_INFO_JSON | awk -F '"|"' '{print $4}')
                BUILD_NUMBER=$(grep buildnumber $STAGE_PKG_DIR/packages/$BUILD_INFO_JSON | awk -F '"|"' '{print $4}')
                BUILD_DATE=$(grep builddate $STAGE_PKG_DIR/packages/$BUILD_INFO_JSON | awk -F '"|"' '{print $4}' | sed -e 's#(#\\(#g' -e 's#)#\\)#g')
                BUILD_VERSION_JSON="/home/dvac/apache2/var/www/portal/build.version.json"
        fi

        if [ $ENVIRONMENT == current ]; then
                # generate index.html and file local.config.json ( old name - "local.json")
                generate_files  $CURRENT_PKG_DIR/packages
                # init users database
                cd $CURRENT_PKG_DIR/packages
                if [ -f server/init.js ]; then
                        node server/init.js
                fi
                 # add URL for development environment
                if [ -f server/config/brandConfig.json ]; then
                        NUM_OF_LINE=$(grep "brandUrl" server/config/brandConfig.json -n | awk -F ":" '{print $1}')
                        sed -i "$NUM_OF_LINE""s#\"brandUrl.*#\"brandUrl\": \"$BRAND_URL/portal/\",#g" server/config/brandConfig.json
                fi
                # run (re-run) node
                start_node $CURRENT_PKG_DIR/packages $INDEX_FILE
        elif [ $ENVIRONMENT == stage ]; then
                if [ ! -d $STAGE_PKG_DIR ]; then mkdir -p $STAGE_PKG_DIR; fi
                time rsync -r --delete --exclude "*.ipa" --exclude "*.apk" --exclude "_oldjson" $CURRENT_PKG_DIR/ $STAGE_PKG_DIR/
                # generate index.html and file local.config.json ( old name - "local.json")
                generate_files  $STAGE_PKG_DIR/packages
                 # init users database
                cd $STAGE_PKG_DIR/packages
                if [ -f server/init.js ]; then
                        node server/init.js
                fi
                 # add URL for development environment
                if [ -f server/config/brandConfig.json ]; then
                        NUM_OF_LINE=$(grep "brandUrl" server/config/brandConfig.json -n | awk -F ":" '{print $1}')
                        sed -i "$NUM_OF_LINE""s#\"brandUrl.*#\"brandUrl\": \"$BRAND_URL/portal/\",#g" server/config/brandConfig.json
                fi
                # run (re-run) node
                start_node $STAGE_PKG_DIR/packages $INDEX_FILE
        elif [ $ENVIRONMENT == public ]; then
                ssh dvac@devzone.dp.ua "if [ ! -d $RSYNC_FACETS_DIR ]; then mkdir -p $RSYNC_FACETS_DIR; fi"
                ssh dvac@devzone.dp.ua "
                        #rm -f $RSYNC_FACETS_DIR/client/dist/app/epubs/dirstructure.json
                        if [ ! -d  $REMOTE_ART_PATH/${combineArray[$i]} ]; then mkdir -p $REMOTE_ART_PATH/${combineArray[$i]}; fi
                        # create of status-deploy file
                        if [ ! -e $REMOTE_ART_PATH/${combineArray[$i]}/status_deploy.txt ]; then touch $REMOTE_ART_PATH/${combineArray[$i]}/status_deploy.txt; fi"
                time rsync -rz --delete --exclude "*.ipa" --exclude "*.apk" --exclude "_oldjson" -e "ssh" $STAGE_PKG_DIR/packages/ dvac@devzone.dp.ua:$RSYNC_FACETS_DIR/
                ssh dvac@devzone.dp.ua "
                        # values
                        INDEX_FILE='index_'$i'_'$BRANCH'_'$ENVIRONMENT'.js'
                        # copying files from RSYNC_FACETS_DIR to REMOTE_ART_PATH/{combineArray[i]}
                        cp -Rf $RSYNC_FACETS_DIR/* $REMOTE_ART_PATH/${combineArray[$i]}/
                        # Shorten path. Because otherwise - > Error of apache named AH00526 (ProxyPass worker name too long)
                        if [ ! -d  $REMOTE_ART_PATH/${combineArray[$i]}/art ]; then mkdir -p $REMOTE_ART_PATH/${combineArray[$i]}/art; fi
                        # generate index.html and file local.config.json ( old name - local.json)
                        /home/dvac/scripts/portgen-deploy-live.sh $BRANCH $i $ENVIRONMENT ${combineArray[$i]}
                        # init users database
                        cd $REMOTE_ART_PATH/${combineArray[$i]}
                        if [ -f server/init.js ]; then
                                ~/node/bin/node server/init.js
                        fi
                        # replace URL for live environment
                        if [ -f server/config/brandConfig.json ]; then
                                sed -i 's#\"brandUrl.*#\"brandUrl\": \"$BRAND_URL/portal/\",#g' server/config/brandConfig.json
                        fi
                        # Start node
                        if [ ! -f server/\$INDEX_FILE ]; then mv server/index_*_stage.js server/\$INDEX_FILE; fi
                        PID=\$(ps aux | grep node.*server/\$INDEX_FILE | grep -v grep | /usr/bin/awk '{print \$2}')
                        if [ ! -z \$PID ]
                        then
                                kill -9 \$PID
                                if [ -f nohup.out ]; then cat /dev/null > nohup.out; fi
                                nohup ~/node/bin/node server/\$INDEX_FILE > nohup.out 2>&1 &
                        else
                                if [ -f nohup.out ]; then cat /dev/null > nohup.out; fi
                                nohup ~/node/bin/node server/\$INDEX_FILE > nohup.out 2>&1 &
                        fi
                        sleep 3
                        rm -f $REMOTE_ART_PATH/${combineArray[$i]}/status_deploy.txt"
                # change versioning values
                ssh dvac@devzone.dp.ua "
                        ## number of version line
                        NUMBER_OF_VERSION_LINE=\$(grep '\"$i\"' $BUILD_VERSION_JSON -A3 -n | grep version | awk -F '-' '{print \$1}')
                        ## replace version for $i target
                        if [ $i == ffa ] || [ $i == ocean ] || [ $i == irls-ocean ] || [ $i == irls-epubtest ]; then
                                eval sed -i \$NUMBER_OF_VERSION_LINE\\\"s#'\'\\\"version.*#'\'\\\"version'\'\\\":'\'\\\"$SPRINT\.$BUILD_NUMBER-dev'\'\\\",#g\\\" $BUILD_VERSION_JSON
                        else
                                eval sed -i \$NUMBER_OF_VERSION_LINE\\\"s#'\'\\\"version.*#'\'\\\"version'\'\\\":'\'\\\"$SPRINT\.$BUILD_NUMBER'\'\\\",#g\\\" $BUILD_VERSION_JSON
                        fi
                        ## number of build date time
                        NUMBER_OF_BUILD_DATE_TIME=\$(grep '\"$i\"' $BUILD_VERSION_JSON -A3 -n | grep buildDateTime | awk -F '-' '{print \$1}')
                        ## replace build date time for $i target
                        eval sed -i \$NUMBER_OF_BUILD_DATE_TIME\\\"s#'\'\\\"buildDateTime.*#'\'\\\"buildDateTime'\'\\\":'\'\\\"$BUILD_DATE'\'\\\"#g\\\" $BUILD_VERSION_JSON
                        ## print of values
                        echo NUMBER_OF_VERSION_LINE=\$NUMBER_OF_VERSION_LINE
                        echo NUMBER_OF_BUILD_DATE_TIME=\$NUMBER_OF_BUILD_DATE_TIME"
                fi
        # update environment.json file
        /home/jenkins/scripts/search_for_environment.sh "${combineArray[$i]}" "$ENVIRONMENT"
        # generate links for web-version of application
        if [ $BRANCHNAME == "master" ];
        then
                echo admin-link-$i-$ENVIRONMENT="$BRAND_URL/admin/dist/app/index_admin.html"
                echo editor-link-$i-$ENVIRONMENT="$BRAND_URL/editor/dist/app/index_editor.html"
                echo reader-link-$i-$ENVIRONMENT="$BRAND_URL/reader/dist/app/index_reader.html"
                echo portal-link-$i-$ENVIRONMENT="$BRAND_URL/portal/dist/app/index_portal.html"
        else
                echo admin-link-$i-$ENVIRONMENT="$BRAND_URL/admin/index_admin.html"
                echo editor-link-$i-$ENVIRONMENT="$BRAND_URL/editor/index_editor.html"
                echo reader-link-$i-$ENVIRONMENT="$BRAND_URL/reader/index_reader.html"
                echo portal-link-$i-$ENVIRONMENT="$BRAND_URL/portal/index_portal.html"
        fi
done
