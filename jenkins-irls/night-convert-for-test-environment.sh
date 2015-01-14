###
### Variables
###

TARGET=(ffa test-target)
CURRENT_EPUBS="$HOME/irls-reader-current-epubs"
RESULTS=$WORKSPACE/results
RRM_PROCESSOR_REPO_NAME="lib-processor"
RRM_OCEAN_REPO_NAME="lib-sources"
TARGETS_REPO_NAME="targets"
#frome node
export NODE_HOME=/opt/node
export PATH=$PATH:$NODE_HOME/bin
# from phantom
export NODE_PATH=/opt/node/lib/node_modules/

###
### Functions
###

function git_clone {
	cd $WORKSPACE
	git clone git@wpp.isd.dp.ua:irls/$REPONAME.git
	}

function git_checkout {
	cd $WORKSPACE/$REPONAME
	git reset --hard
	git clean -fdx
	git fetch --all
	git checkout origin/$1
	}

function check_repo {
	if [ ! -d $WORKSPACE/$1 ]; then
		git_clone
		git_checkout $2
	else
		git_checkout $2
	fi
	}

### Checkout code from repositories
REPONAME=$RRM_PROCESSOR_REPO_NAME
check_repo $REPONAME develop
REPONAME=$RRM_OCEAN_REPO_NAME
check_repo $REPONAME master
REPONAME=$TARGETS_REPO_NAME
check_repo $REPONAME master

### Convert
for TARGET_NAME in ${TARGET[@]}
do
	### Determine facet name from target
	FACET_NAME=$(grep facet $WORKSPACE/$TARGETS_REPO_NAME/$TARGET_NAME/targetConfig.json | awk -F'"|"' '{print $4}')
	if [ -z $FACET_NAME ]; then echo "FACET_NAME is not determined!" && exit 1; fi
	### Clean old "facet named"-directory
	rm -rf $RESULTS/$FACET_NAME
	mkdir -p $RESULTS/$FACET_NAME
	cd $WORKSPACE/$RRM_PROCESSOR_REPO_NAME/src
	### Processing raw texts
	#time node main.js $WORKSPACE/$RRM_OCEAN_REPO_NAME $RESULTS/$FACET_NAME $FACET_NAME
	time node main.js -s $WORKSPACE/$RRM_OCEAN_REPO_NAME -d $RESULTS/$FACET_NAME -f $FACET_NAME -t $WORKSPACE/tmp
	time node --max-old-space-size=7000 $WORKSPACE/$RRM_PROCESSOR_REPO_NAME/src/createJSON.js $RESULTS/$FACET_NAME/
	### Create (if not exist) current "target named"-, "current epub"-directory
	if [ ! -d $CURRENT_EPUBS/$TARGET_NAME ]; then mkdir -p $CURRENT_EPUBS/$TARGET_NAME; fi
	### Copy epubs after their processing to the "current epubs"-directory
	time rsync -rv --delete $RESULTS/$FACET_NAME/ $CURRENT_EPUBS/$TARGET_NAME/
done
