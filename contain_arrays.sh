#!/bin/bash
FACETS=(puddle bahaiebooks lake ocean)
ID="74d1d18c9844eae001ed9_puddle 74d1d18c9844eae001ed9_bahaiebooks 74d1d18c9844eae001ed9_lake 74d1d18c9844eae001ed9_ocean"

deploymentPackageId=($(echo $ID))

declare -A combineArray

for ((i=0; i<${#deploymentPackageId[@]}; i++))
do
	
	for ((y=0; y<${#FACETS[@]}; y++))
	do
		if [ -n "$(echo "${deploymentPackageId[i]}" | grep "${FACETS[y]}")" ]; then
			combineArray+=(["${FACETS[y]}"]="${deploymentPackageId[i]}")
		fi
	done
done

for K in "${!combineArray[@]}"; do echo $K --- ${combineArray[$K]}; done
