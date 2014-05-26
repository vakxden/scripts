#!/bin/bash

# hard code
ID="dda0385c9c1fce2ce1259_puddle dda0385c9c1fce2ce1259_bahaiebooks dda0385c9c1fce2ce1259_mediaoverlay dda0385c9c1fce2ce1259_audio dda0385c9c1fce2ce1259_audiobywords dda0385c9c1fce2ce1259_lake"
FACETS=(puddle bahaiebooks mediaoverlay audio audiobywords lake ocean)
# array
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
# output
for i in "${!combineArray[@]}"
do
	echo $i --- ${combineArray[$i]}
done
