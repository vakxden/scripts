if [ "$BRANCHNAME" = "master" ] || [ "$BRANCHNAME" = "" ]; then
        #FACET=(puddle epubtest gutenberg refbahai farsi farsi3 bahaiebooks audio audiobywords mediaoverlay lake ocean)
	FACET=(audiobywords)
        for i in ${FACET[@]}
        do
                curl http://wpp.isd.dp.ua/jenkins/job/irls-rrm-processor-convert/buildWithParameters?token=Sheedah8\&FACET=$i
        done
fi
