if [ "$BRANCHNAME" = "master" ]; then
        #FACET=(puddle refbahai farsi farsi3 bahaiebooks audio audiobywords mediaoverlay lake ocean)
        FACET=(audio refbahai audiobywords)
        for i in ${FACET[@]}
        do
                curl http://wpp.isd.dp.ua/jenkins/view/irls-rrm-processor/job/irls-rrm-processor-convert/buildWithParameters?token=Sheedah8\&FACET=$i
        done
fi
