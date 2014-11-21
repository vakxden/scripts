#!/bin/bash

if [ -z $1 ]; then
        echo "Enter please BRANCHNAME as first parameter"
        exit 1
fi
BRANCHNAME=$1
BRANCH=$(echo $1 | sed 's@/@-@g')
if [ -z $2 ]; then
        echo "Enter please TARGETNAME as second parameter"
        exit 1
fi
TARGETNAME=$2
BRAND=$(grep "brand" /Users/jenkins/git/targets/$TARGETNAME/targetConfig.json | awk -F'"|"' '{print $4}')

cd /Users/jenkins/git/reader
echo "git reset --hard for reader repo"
git reset --hard
echo "git clean -fdx for reader repo"
git clean -fdx
echo "git fetch --all for reader repo"
git fetch --all
echo "git checkout origin/$BRANCHNAME for reader repo"
git checkout origin/$BRANCHNAME

cd /Users/jenkins/git/targets
echo "git fetch --all for targets repo"
git fetch --all
echo "git checkout origin/master for targets repo"
git checkout origin/master

cd /Users/jenkins/git/reader/client
echo "Start build and verify"
node compileHandlebars.js
node index.js --target=$TARGETNAME --targetPath=/Users/jenkins/git/targets --readerPath=/Users/jenkins/git/reader
grunt verify
grunt productionCompile
cp -Rf /Users/jenkins/git/reader/client/out/dist/* /Users/jenkins/git/reader/client/
cd /Users/jenkins/git/reader/packager
echo "{}" > /Users/jenkins/git/reader/client/meta.json
node index.js --platform=ios --config=/Users/jenkins/git/targets --from=/Users/jenkins/git/reader/client --prefix=$BRANCH- --epubs=/Users/jenkins/irls-reader-current-epubs

echo ""
echo "Good news, username!"
echo "The xcode-project will be located at the following path: "
echo /Users/jenkins/git/reader/packager/out/dest/platforms/ios/$BRANCH-$BRAND\_Reader-$TARGETNAME.xcodeproj
echo ""
