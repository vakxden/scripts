if [ "$BRANCHNAME" = "master" ]; then
	#FACET=(puddle farsi farsiref bahaiebooks audio audiobywords mediaoverlay lake ocean)
	FACET=(farsi)
	for i in ${FACET[@]}
	do
		curl http://wpp.isd.dp.ua/jenkins/view/irls-rrm-processor/job/irls-rrm-processor-convert/buildWithParameters?token=Sheedah8\&FACET=$i
	done
elif [ "$BRANCHNAME" = "audio" ]; then
	FACET=(audio)
	for i in ${FACET[@]}
	do
		curl http://wpp.isd.dp.ua/jenkins/view/irls-rrm-processor/job/irls-rrm-processor-convert/buildWithParameters?token=Sheedah8\&FACET=$i
	done
else
	exit 1
fi
