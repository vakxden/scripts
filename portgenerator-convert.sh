#!/bin/bash
BRANCHNAME="$1"
LIBRARY_SIZE="$2"
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

#echo "generated port: $GENERATED_PORT"
### Create file local.json
rm -f local.json
touch local.json
echo '{' >> local.json
echo -e '\t"libraryDir" : "/home/jenkins/reader-library/'$LIBRARY_SIZE'/'$BRANCHNAME'/",' >> local.json
echo -e '\t"listenPort"':$GENERATED_PORT, >> local.json
echo -e '\t"database_name": "'$LIBRARY_SIZE'_'$BRANCHNAME'"' >> local.json
echo '}'  >> local.json
