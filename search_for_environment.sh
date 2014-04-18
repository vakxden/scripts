#!/bin/bash -x
for i in e87c5e722febc61e5c5be_puddle e87c5e722febc61e5c5be_bahaiebooks e87c5e722febc61e5c5be_lake e87c5e722febc61e5c5be_ocean e87c5e722febc61e5c5be_audio e87c5e722febc61e5c5be_mediaoverlay
do
	# count of strings in block, named "current", or "stage" or "live"
	a=$((($(cat environment.json | wc -l)-8)/3))
	# find ID in block named "current", or "stage" or "live"
	grep current -A $a environment.json | grep $i
	# if ID not found check exist name FACET in current ID in block named "current", or "stage" or "live"
	if [ echo $? -eq 1 ]; then
		facet=$(echo $i | sed 's/^.*_//g')
		grep current -A $a environment.json | grep $facet 
		if [ echo $? -eq 1 ]; then
			# how to insert a row into the right block?
			echo -e >> environment.json
		else
			# how to delete a row into the right block?
			# delete string from block named "current"
			# insert $i to environment.json
		fi
	fi
done
