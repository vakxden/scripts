if [ "$BRANCHNAME" = "master" ]; then
	FACET=(puddle farsi farsi2 farsiref bahaiebooks audio audiobywords mediaoverlay lake ocean)
	for i in ${FACET[@]}
	do
		curl http://wpp.isd.dp.ua/jenkins/view/irls-rrm-processor/job/irls-rrm-processor-convert/buildWithParameters?token=Sheedah8\&FACET=$i
	done
fi
