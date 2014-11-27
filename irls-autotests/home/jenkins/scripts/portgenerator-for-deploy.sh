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
ID="$3"

if [ -z $BRANCHNAME ]; then
    echo "Branchname must be passed"
    exit 1
fi

if [ -z $FACETS ]; then
    echo "Facets must be passed"
    exit 1
fi

if [ -z $ID ]; then
    echo "ID must be passed"
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
        echo -e '\t"libraryDir" : "/home/jenkins/irls-reader-artifacts/'$ID'/packages/client/dist/app/epubs/",' >> local.json
        echo -e '\t"listenPort"':$GENERATED_PORT, >> local.json
        echo -e '\t"database_name": "'$FACETS'",' >> local.json
        echo -e '\t"environment_name": "'$CURRENT'"' >> local.json
        echo '}'  >> local.json
        }



CURRENT="test"
ARTDIR="irls-reader-artifacts"
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
fi

echo -e '\t'ProxyPass /irls/$CURRENT/reader/$FACETS/$BRANCHNAME/ http://127.0.0.1:$GENERATED_PORT/ >> $ACF
echo -e '\t'ProxyPassReverse /irls/$CURRENT/reader/$FACETS/$BRANCHNAME/ http://127.0.0.1:$GENERATED_PORT/ >> $ACF
service apache2 reload
rm -f $lockfile
