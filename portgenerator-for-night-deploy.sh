#!/bin/bash -x
name=$(basename $0)
lockfile=/var/tmp/$name
while [ -f $lockfile ]
do
        printf "Script $name already running. Lock file is $lockfile"
        sleep 2
done

                # body of script
                touch $lockfile
                BRANCHNAME="$1"
                FACETS="$2"
                dest="$3"
                ID="$4"

                if [ -z $BRANCHNAME ]; then
                    echo "Branchname must be passed"
                    exit 1
                fi

                if [ -z $FACETS ]; then
                    echo "Facets must be passed"
                    exit 1
                fi

                if [ -z $dest ]; then
                    echo "Destination must be passed"
                    exit 1
                fi


                ### ARRAY_RESERVED_SERVICE_PORT
                ARRAY_RSP=($(cat /etc/services | awk '{print $2}' | grep "^3[0-9][0-9][0-9]" | grep -v "^3[0-9][0-9][0-9][0-9]" | awk -F "/" '{print $1}' | sort | uniq))
                ### ARRAY_CURRENTLY_USED_PORT
                ARRAY_CUP=($(netstat -nlpt | awk '{print $4}' | egrep "^0|^127" | awk -F ":" '{print $2}' | grep "^3[0-9][0-9][0-9]" | grep -v "^3[0-9][0-9][0-9][0-9]" | sort | uniq))
                ### CONCATENATION TWO ARRAYS - ARRAY_RESERVED_SERVICE_PORT AND ARRAY_CURRENTLY_USED_PORT
                CONCAT_ARRAY=(${ARRAY_RSP[@]} ${ARRAY_CUP[@]})

                function generate_port {
                        echo $(shuf -i 3000-3999 -n 1)
                }

                array_contains () {
                    local seeking=$1; shift
                    local in=1

                    for element; do
                        if [[ $element == $seeking ]]; then
                            in=0
                            break
                        fi
                    done
                    return $in
                }

                GENERATED_PORT=$(generate_port)

                while [[ "$(array_contains "$GENERATED_PORT" "${CONCAT_ARRAY[@]}" && echo $?)" == "0" ]]
                do
                        GENERATED_PORT=0
                        GENERATED_PORT=$(generate_port)
                done

                function generate_localjson {
                        ### Create file local.json
                        cat /dev/null > local.json
                        echo '{' >> local.json
                        echo -e '\t"libraryDir" : "/home/jenkins/'$ARTDIR'/'$ID'/packages/client/dist/app/epubs/",' >> local.json
                        echo -e '\t"listenPort"':$GENERATED_PORT, >> local.json
                        #echo -e '\t"database_name": "'$FACETS'_night",' >> local.json
                        echo -e '\t"database_name": "'$FACETS'",' >> local.json
                        echo -e '\t"environment_name": "'$CURRENT'"' >> local.json
                        echo '}'  >> local.json
                        chown jenkins:jenkins local.json
                }

                function generate_indexhtml {
                        ### generate index.html
                        cd /home/jenkins/$ARTDIR/$ID/packages/artifacts/
                        cat /dev/null > index.html
                        chown jenkins:jenkins index.html
                        echo -e '<!DOCTYPE HTML>' >> index.html
                        echo -e '<html><head><title>List of artifacts</title></head>' >> index.html
                        echo -e '<body><h1>List of artifacts</h1>' >> index.html
                        echo -e '<table><tr><th><a href="?C=N;O=D">Name</a></th><th><a href="?C=M;O=A">Last modified</a></th><th><a href="?C=S;O=A">Size</a></th></tr><tr><th colspan="5"><hr></th></tr>' >> index.html
                        IPAFILE=$BRANCHNAME*_Reader*$FACETS*.ipa
                        ZIPWINFILE=$BRANCHNAME*_Reader*$FACETS-win*.zip
                        DEB32=$BRANCHNAME-reader-$FACETS*i386.deb
                        DEB64=$BRANCHNAME-reader-$FACETS*amd64.deb
                        ZIPMACOSFILE=$BRANCHNAME*_Reader*$FACETS-macos*.zip
                        APKFILE=$BRANCHNAME*_Reader*$FACETS*.apk
                        for file in $IPAFILE $ZIPWINFILE $APKFILE $ZIPMACOSFILE $DEB32 $DEB64
                        do
                                if [ -f "$(find . -name $file)" ]; then
                                        for name in $(find . -name $file)
                                        do
                                                DATE=$(stat -c %y $name | awk '{print $1,$2}' | awk -F'.' '{print $1}')
                                                SIZE=$(($(stat -c %s $name)/1048576))
                                                artifact_name=$(echo $name |  sed 's/^\.\///g')
                                                echo -e '<tr><td><a href="http://wpp.isd.dp.ua/irls/'$CURRENT'/reader/'$FACETS'/'$BRANCHNAME'/artifacts/'$artifact_name'">'$artifact_name'</a></td><td align="right">'$DATE'</td><td align="right">'$SIZE'MB</td><td>&nbsp;</td></tr>' >> index.html
                                        done
                                fi
                        done
                        echo -e '<tr><th colspan="5"><hr></th></tr></table></body></html>' >> index.html
                        cd ../
                }

                function dest_eq_development {
                        generate_localjson
                        ### Touch apache config file
                        ACF="/etc/apache2/sites-enabled/irls-$CURRENT-reader-$FACETS-$BRANCHNAME"
                        rm -f $ACF
                        touch $ACF
                        if [ -z $ID ]; then
                                echo "ID was not passed"
                        else
                                if [ ! -d /home/jenkins/$ARTDIR/$ID/packages/artifacts ]; then
                                        mkdir -p /home/jenkins/$ARTDIR/$ID/packages/artifacts && chown -Rf jenkins:jenkins /home/jenkins/$ARTDIR/$ID/packages/artifacts
                                fi
                                echo -e '\t'ProxyPass /irls/$CURRENT/reader/$FACETS/$BRANCHNAME/artifacts  http://127.0.0.1/$ARTDIR/$ID/packages/artifacts/ >> $ACF
                                echo -e '\t'ProxyPassReverse /irls/$CURRENT/reader/$FACETS/$BRANCHNAME/artifacts  http://127.0.0.1/$ARTDIR/$ID/packages/artifacts/ >> $ACF
                                generate_indexhtml
                        fi

                        echo -e '\t'ProxyPass /irls/$CURRENT/reader/$FACETS/$BRANCHNAME/ http://127.0.0.1:$GENERATED_PORT/ >> $ACF
                        echo -e '\t'ProxyPassReverse /irls/$CURRENT/reader/$FACETS/$BRANCHNAME/ http://127.0.0.1:$GENERATED_PORT/ >> $ACF
                        service apache2 reload
                }

                function dest_eq_stage {
                        generate_localjson
                        ### if apache config file exist then create temporary file
                        ACF="/etc/apache2/sites-enabled/irls-$CURRENT-reader-$FACETS-$BRANCHNAME"
                        #if [ -f $ACF ]; then
                        #       grep "http://127.0.0.1:[0-9][0-9][0-9][0-9]/" $ACF >> tmp
                        #fi
                        if [ -z $ID ]; then
                                echo "ID was not passed"
                        else
                                if [ ! -d /home/jenkins/$ARTDIR/$ID/packages/artifacts ]; then
                                        mkdir -p /home/jenkins/$ARTDIR/$ID/packages/artifacts && chown -Rf jenkins:jenkins /home/jenkins/$ARTDIR/$ID/packages/artifacts
                                fi
                                # filling temporary file
                                echo -e '\t'ProxyPass /irls/$CURRENT/reader/$FACETS/$BRANCHNAME/artifacts  http://127.0.0.1/$ARTDIR/$ID/packages/artifacts/ >> tmp
                                echo -e '\t'ProxyPassReverse /irls/$CURRENT/reader/$FACETS/$BRANCHNAME/artifacts  http://127.0.0.1/$ARTDIR/$ID/packages/artifacts/ >> tmp
                                generate_indexhtml
                        fi
                        # replace temporary file to original apache config file
                        echo -e '\t'ProxyPass /irls/$CURRENT/reader/$FACETS/$BRANCHNAME/ http://127.0.0.1:$GENERATED_PORT/ >> tmp
                        echo -e '\t'ProxyPassReverse /irls/$CURRENT/reader/$FACETS/$BRANCHNAME/ http://127.0.0.1:$GENERATED_PORT/ >> tmp
                        cp -f tmp $ACF
                        rm -f tmp
                        service apache2 reload
                }


                if [ "$dest" = "DEVELOPMENT" ]; then
                        CURRENT="current"
                        ARTDIR="irls-reader-artifacts"
                        dest_eq_development
                elif [ "$dest" = "STAGE" ]; then
                        CURRENT="stage"
                        ARTDIR="irls-reader-artifacts-stage"
                        dest_eq_stage
                elif [ "$dest" = "LIVE" ]; then
                        CURRENT="live"
                elif [ "$dest" = "NIGHT" ]; then
                        CURRENT="night"
                        ARTDIR="irls-reader-artifacts-nightly"
                        dest_eq_stage
                fi
                rm -f $lockfile
