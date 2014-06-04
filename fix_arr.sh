#!/bin/bash

# hard code
ID="c82a41d5a28a543e182aa_puddle c82a41d5a28a543e182aa_bahaiebooks c82a41d5a28a543e182aa_audio c82a41d5a28a543e182aa_audiobywords c82a41d5a28a543e182aa_mediaoverlay c82a41d5a28a543e182aa_lake c82a41d5a28a543e182aa_ocean"
FACETS=(puddle bahaiebooks audio audiobywords mediaoverlay lake ocean)
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
