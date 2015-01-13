sleep 15

### Variables of repositories
READER_REPONAME="product"

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

### Cloning of product-repo
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
ENV_CONFIG="$WORKSPACE/$READER_REPONAME/tests/data/environmentConfig.json"
cat $ENV_CONFIG
cat /dev/null > $ENV_CONFIG
echo -e '{\n"url":"http://irls-autotests.design.isd.dp.ua/irls/test/reader/test-target/develop/"\n}' >> $ENV_CONFIG
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
