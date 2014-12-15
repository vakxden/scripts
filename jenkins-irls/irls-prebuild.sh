# This job runs from post-receive hook:
# /home/git/repositories/irls/product.git/hooks/post-receive or
# /home/git/repositories/irls/targets.git/hooks/post-receive or
# /home/git/repositories/irls/lib-processor.git/hooks/post-receive or
# /home/git/repositories/irls/lib-sources.git/hooks/post-receive
# with help of next command:
# wget -qO- --auth-no-challenge --http-user=dvac --http-password="0f64d6238d107249f79deda4d6a2f9fc" http://wpp.isd.dp.ua/jenkins/job/irls-reader-prebuild/buildWithParameters\?token=Sheedah8\&REPONAME=$REPONAME\&BRANCH=$BRANCH &> /dev/null
# P.S. Link for post-receive+run of jenkins job: http://blog.avisi.nl/2012/01/13/push-based-builds-using-jenkins-and-git/

if [ -z $REPONAME ]; then
	echo \[ERROR_REPO\] reponame not passed!
	exit 1
fi

if [ -z $BRANCH ]; then
	echo \[ERROR_BRANCH\] branch not passed!
	exit 1
fi

function git_clone {
	cd $WORKSPACE
	git clone git@wpp.isd.dp.ua:irls/$REPONAME.git
	}

function git_checkout {
	cd $WORKSPACE/$REPONAME
	git reset --hard
	git clean -fdx
	git fetch --all
	git checkout origin/$BRANCH
	}

if [ "$REPONAME" == "product" ]; then
        if [ ! -d $WORKSPACE/$REPONAME ]; then
                git_clone
                git_checkout
        else
                git_checkout
        fi
        LIST_OF_ALL_TARGETS=($(cd $WORKSPACE/targets; ls -d ./* | sed s@\./@@g ))
        for i in "${LIST_OF_ALL_TARGETS[@]}"
        do
                BRANCHNAME=""
                BRANCHNAME=($(grep branch $WORKSPACE/targets/$i/targetConfig.json | awk -F '"|"' '{print $4}' | sed 's@,@ @g'))
                for y in "${BRANCHNAME[@]}"
                do
                        if [ -z $y ]; then
                                continue
                        else
				if [[ $BRANCH == $y ]]; then
                                        curl http://wpp.isd.dp.ua/jenkins/job/irls-reader-build/buildWithParameters?token=Sheedah8\&TARGET=$i\&BRANCHNAME=$BRANCH\&STARTED_BY=$JOB_NAME%20$BUILD_NUMBER
                                fi
                        fi
                done
        done
	echo \[WARN_MARK\] Started by commit to repo \<b\>$REPONAME\</b\>\<br\> run the \<a href="http://wpp.isd.dp.ua/jenkins/job/irls-reader-build" title="irls-reader-build"\>irls-reader-build\</a\> job
elif [ "$REPONAME" == "targets" ]; then
        if [ ! -d $WORKSPACE/$REPONAME ]; then
                git_clone
                git_checkout
        else
                git_checkout
        fi
        LIST_OF_ALL_TARGETS=($(cd $WORKSPACE/$REPONAME; ls -d ./* | sed s@\./@@g ))
        for i in "${LIST_OF_ALL_TARGETS[@]}"
        do
                BRANCHNAME=""
                BRANCHNAME=($(grep branch $WORKSPACE/$REPONAME/$i/targetConfig.json | awk -F '"|"' '{print $4}' | sed 's@,@ @g'))
                for y in "${BRANCHNAME[@]}"
                do
                        if [ -z $y ]; then
                                continue
                        else
                		curl http://wpp.isd.dp.ua/jenkins/job/irls-reader-build/buildWithParameters?token=Sheedah8\&TARGET=$i\&BRANCHNAME=develop\&STARTED_BY=$JOB_NAME%20$BUILD_NUMBER
                        fi
                done
        done
	echo \[WARN_MARK\] Started by commit to repo \<b\>$REPONAME\</b\>\<br\> run the \<a href="http://wpp.isd.dp.ua/jenkins/job/irls-reader-build" title="irls-reader-build"\>irls-reader-build\</a\> job
elif [ "$REPONAME" == "lib-processor" ]; then
	if [ "$BRANCH" == "master" ]; then
		curl curl http://wpp.isd.dp.ua/jenkins/job/1-irls-lib-processor-build/buildWithParameters?token=Sheedah8\&BRANCHNAME=$BRANCH
	fi
	echo \[WARN_MARK\] Started by commit to repo \<b\>$REPONAME\</b\>\<br\> run the \<a href="http://wpp.isd.dp.ua/jenkins/job/1-irls-lib-processor-build" title="1-irls-lib-processor-build"\>1-irls-lib-processor-build\</a\> job
elif [ "$REPONAME" == "lib-sources" ]; then
	if [ "$BRANCH" == "master" ]; then
		curl curl http://wpp.isd.dp.ua/jenkins/job/1-irls-lib-sources-build/buildWithParameters?token=Sheedah8\&BRANCHNAME=$BRANCH
	fi
	echo \[WARN_MARK\] Started by commit to repo \<b\>$REPONAME\</b\>\<br\> run the \<a href="http://wpp.isd.dp.ua/jenkins/job/1-irls-lib-sources-build" title="1-irls-lib-sources-build"\>1-irls-lib-sources-build\</a\> job
else
	echo \[ERROR_REPO\] Wrong reponame!
	exit 1
fi
