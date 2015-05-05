#!/bin/bash

ART_PATH="/home/jenkins/irls-reader-artifacts/"
COUNT=$(ls -Ahtr $ART_PATH | wc -l)
TAIL=$(($COUNT-5))
cd $ART_PATH
ls -Ahtr | head -$TAIL | xargs rm -rf
