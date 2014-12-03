### Variables of repositories
READER_REPONAME="reader"

### Functions for git command
function git_clone {
        cd $WORKSPACE
        git clone git@wpp.isd.dp.ua:irls/$REPONAME.git
        }

function git_checkout {
        cd $WORKSPACE/$REPONAME
        git reset --hard
        git clean -fdx
        git fetch --all
        git checkout origin/$BRANCHNAME
        }

### Cloning of reader-repo
REPONAME="$READER_REPONAME"
if [ ! -d $WORKSPACE/$REPONAME ]; then
        git_clone
        git_checkout
else
        git_checkout
fi
export DISPLAY=:99
export NODE_HOME=/opt/node
export PATH=$PATH:$NODE_HOME/bin
### Changing URL for tests
cat $WORKSPACE/$READER_REPONAME/tests/environmentConfig.json
cat /dev/null > $WORKSPACE/$READER_REPONAME/tests/environmentConfig.json
echo -e '{\n"url":"http://irls-autotests.design.isd.dp.ua/irls/test/reader/test-target/develop/portal/"\n}' >> $WORKSPACE/$READER_REPONAME/tests/environmentConfig.json
cat $WORKSPACE/$READER_REPONAME/tests/environmentConfig.json
### Running tests
cd $WORKSPACE/$READER_REPONAME/tests/spec
#which chromedriver
### It's command already started
### Check it from command line: netstat -nlpt | grep 4444
# java -jar /opt/selenium-server-standalone-2.37.0.jar -Dwebdriver.chrome.driver="/opt/chromedriver"
### Old command from running of tests
# jasmine-node reader-spec.js --junitreport --verbose
grunt
