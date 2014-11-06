if [ "$REPONAME" == "reader" ]; then
	if [ ! -d reader ]; then
		git clone git@wpp.isd.dp.ua:irls/reader.git
		cd reader
		git pull
		git checkout $BRANCH
	else
		cd reader
		git pull
		git checkout $BRANCH
	fi
elif [ "$REPONAME" == "targets" ]; then
	if [ ! -d targets ]; then
		git clone git@wpp.isd.dp.ua:irls/targets.git
		cd targets
		git pull
		git checkout $BRANCH
	else
		cd targets
		git pull
		git checkout $BRANCH
	fi
fi

# run from post-commit hook
# run with
# wget -qO- --auth-no-challenge --http-user=dvac --http-password="0f64d6238d107249f79deda4d6a2f9fc" http://wpp.isd.dp.ua/jenkins/job/determine_of_branch/buildWithParameters\?token=Ahgoo8Ah\&REPONAME=reader\&BRANCH=develop &> /dev/null
