#!/bin/bash
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

if [ "$dest" = "DEVELOPMENT" ]; then
        CURRENT="current"
                elif [ "$dest" = "STAGE" ]; then
        CURRENT="stage"
                elif [ "$dest" = "LIVE" ]; then
        CURRENT="live"
fi

#echo "generated port: $GENERATED_PORT"
### Create file local.json
rm -f local.json
touch local.json
echo '{' >> local.json
echo -e '\t"libraryDir" : "/home/dvac/irls-reader-current-epubs/'$FACETS'/",' >> local.json
echo -e '\t"listenPort"':$GENERATED_PORT, >> local.json
echo -e '\t"database_name": "'$FACETS'"' >> local.json
echo '}'  >> local.json

### Touch apache config file
ACF="/home/dvac/apache2/conf/extra/proxypass-$FACETS-$BRANCHNAME.conf"
rm -f $ACF
touch $ACF
if [ -z $ID ]; then
         echo "ID was not passed"
else
        echo -e '\t'ProxyPass /$FACETS/$BRANCHNAME.artifacts  http://127.0.0.1:8890/irls-reader-artifacts/$ID/packages/ >> $ACF
        echo -e '\t'ProxyPassReverse /$FACETS/$BRANCHNAME.artifacts  http://127.0.0.1:8890/irls-reader-artifacts/$ID/packages/ >> $ACF
fi

echo -e '\t'ProxyPass /$FACETS/$BRANCHNAME/ http://127.0.0.1:$GENERATED_PORT/ >> $ACF
echo -e '\t'ProxyPassReverse /$FACETS/$BRANCHNAME/ http://127.0.0.1:$GENERATED_PORT/ >> $ACF
/home/dvac/apache2/bin/apachectl restart
