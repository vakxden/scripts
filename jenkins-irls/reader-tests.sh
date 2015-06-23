READER_REPONAME="product"
rm -rf $WORKSPACE/*
mkdir -p $WORKSPACE/$READER_REPONAME
cp -Rf $HOME/irls-reader-current-build/$GIT_COMMIT-$TARGET/* $WORKSPACE/$READER_REPONAME/
export DISPLAY=:99
export NODE_HOME=/opt/node
export PATH=$PATH:$NODE_HOME/bin
### Changing URL for tests
ENV_CONFIG="$WORKSPACE/$READER_REPONAME/tests/data/environmentConfig.json"
cat $ENV_CONFIG
cat /dev/null > $ENV_CONFIG
-echo -e '{\n"url":"http://irls-autotests.design.isd.dp.ua/irls/test/reader/$TARGET/$BRANCHNAME/"\n}' >> $ENV_CONFIG
cat $ENV_CONFIG
### Running tests
cd $WORKSPACE/$READER_REPONAME/tests/spec
#which chromedriver
### It's command already started
#Check it from command line: /bin/netstat -nlpt | grep 4444
# java -jar /opt/selenium-server-standalone-2.44.0.jar -Dwebdriver.chrome.driver="/opt/node/bin/chromedriver"
### Old command from running of tests
# jasmine-node reader-spec.js --junitreport --verbose
grunt
### Archiving test results and screenshots
ssh jenkins@dev01.isd.dp.ua "if [ ! -d /var/lib/jenkins/jobs/$JOB_NAME/builds/$BUILD_ID/archive ]; then mkdir -p /var/lib/jenkins/jobs/$JOB_NAME/builds/$BUILD_ID/archive/{reports,screenshots}; fi"
scp $WORKSPACE/$READER_REPONAME/tests/reports/*.xml jenkins@dev01.isd.dp.ua:/var/lib/jenkins/jobs/$JOB_NAME/builds/$BUILD_ID/archive/reports/
if [ "$(ls -A $WORKSPACE/$READER_REPONAME/tests/screenshots)" ]; then
    echo "Directory $WORKSPACE/$READER_REPONAME/tests/screenshots is not empty"
	scp $WORKSPACE/$READER_REPONAME/tests/screenshots/*.png jenkins@dev01.isd.dp.ua:/var/lib/jenkins/jobs/$JOB_NAME/builds/$BUILD_ID/archive/screenshots/
else
    echo "directory $WORKSPACE/$READER_REPONAME/tests/screenshots is empty"
fi
