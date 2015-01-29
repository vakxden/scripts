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

cd /Users/jenkins/git/product
echo "git reset --hard for product repo"
git reset --hard
echo "git clean -fdx for product repo"
git clean -fdx
echo "git fetch --all for product repo"
git fetch --all
echo "git checkout origin/$BRANCHNAME for product repo"
git checkout origin/$BRANCHNAME

cd /Users/jenkins/git/targets
echo "git fetch --all for targets repo"
git fetch --all
echo "git checkout origin/master for targets repo"
git checkout origin/master

cd /Users/jenkins/git/product/client
echo "Start build and verify"
npm install grunt-compile-handlebars
#node compileHandlebars.js
node index.js --target=$TARGETNAME --targetPath=/Users/jenkins/git/targets --readerPath=/Users/jenkins/git/product
#grunt verify
#grunt productionCompile
grunt production
cp -Rf /Users/jenkins/git/product/client/out/dist/* /Users/jenkins/git/product/client/
if [ ! -d /Users/jenkins/git/product/packager/build ]; then mkdir -p /Users/jenkins/git/product/packager/build; fi
cp -Rf ~/git/build_re/phonegap-plugins /Users/jenkins/git/product/packager/build/
cd /Users/jenkins/git/product/packager
echo "{}" > /Users/jenkins/git/product/client/meta.json
node index.js --platform=ios --config=/Users/jenkins/git/targets --from=/Users/jenkins/git/product/client --prefix=$BRANCH- --epubs=/Users/jenkins/irls-reader-current-epubs

echo ""
echo "Good news, username!"
echo "The xcode-project will be located at the following path: "
echo /Users/jenkins/git/product/packager/out/dest/platforms/ios/$BRANCH-$BRAND\_Reader-$TARGETNAME.xcodeproj
echo ""
