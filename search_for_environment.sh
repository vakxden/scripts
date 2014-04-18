#!/bin/bash -x
for i in e87c5e722febc61e5c5be_puddle e87c5e722febc61e5c5be_bahaiebooks e87c5e722febc61e5c5be_lake e87c5e722febc61e5c5be_ocean e87c5e722febc61e5c5be_audio e87c5e722febc61e5c5be_mediaoverlay
do
	a=$((($(cat environment.json | wc -l)-8)/3))
	grep current -A $a environment.json | grep $i
	if [ echo $? -eq 1 ]; then

done
