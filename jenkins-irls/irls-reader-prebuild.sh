# This job runs from post-receive hook (/home/git/repositories/irls/reader.git/hooks/post-receive or /home/git/repositories/irls/targets.git/hooks/post-receive)
# with help of next command:
# wget -qO- --auth-no-challenge --http-user=dvac --http-password="0f64d6238d107249f79deda4d6a2f9fc" http://wpp.isd.dp.ua/jenkins/job/determine_of_branch/buildWithParameters\?token=Ahgoo8Ah\&REPONAME=reader\&BRANCH=develop &> /dev/null
# P.S. Link for post-receive+run of jenkins job: http://blog.avisi.nl/2012/01/13/push-based-builds-using-jenkins-and-git/

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

if [ "$REPONAME" == "reader" ]; then
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
                                        curl http://wpp.isd.dp.ua/jenkins/job/irls-reader-build/buildWithParameters?token=Sheedah8\&TARGET=$i\&BRANCHNAME=$BRANCH
                                fi
                        fi
                done
        done
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
                		curl http://wpp.isd.dp.ua/jenkins/job/irls-reader-build/buildWithParameters?token=Sheedah8\&TARGET=$i\&BRANCHNAME=develop
                        fi
                done
        done
fi
echo "Checkout, please, of running/not_running next job: http://wpp.isd.dp.ua/jenkins/job/irls-reader-build"
