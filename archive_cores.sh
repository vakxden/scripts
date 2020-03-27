#!/bin/bash

PATH_TO_CORE_DIR=/path/to/core/files

for each_file in $(find ${PATH_TO_CORE_DIR} -type f | grep -v stack);
do
    echo "archiving ${each_file} ..."
    tar cfz ${each_file}.tar.gz ${each_file}
    if [ $? -ne 0 ]; then
        echo "Failed to archive ${each_file}"
        echo "Exit."
        exit 1
    fi
    echo "archive ${each_file}.tar.gz created."
    ls -lah ${each_file}.tar.gz
    echo "deleting ${each_file} ..."
    rm -f ${each_file}
done
