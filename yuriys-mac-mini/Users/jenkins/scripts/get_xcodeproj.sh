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

cd /Users/jenkins/git/product/build
echo "Start build and verify"
npm install grunt-compile-handlebars
#node compileHandlebars.js
node index.target.js --target=$TARGETNAME --targetPath=/Users/jenkins/git/targets --readerPath=/Users/jenkins/git/product
#grunt verify
#grunt productionCompile
#grunt production
grunt
#cp -Rf /Users/jenkins/git/product/build/out/dist/* /Users/jenkins/git/product/build/
cp -Rf /Users/jenkins/git/product/build/out/* /Users/jenkins/git/product/build/
if [ ! -d /Users/jenkins/git/product/build/build ]; then mkdir -p /Users/jenkins/git/product/build/build; fi
if [ -d /Users/jenkins/build_re/$BRANCHNAME ]; then
        cp -Rf /Users/jenkins/build_re/$BRANCHNAME/phonegap-plugins /Users/jenkins/git/product/build/build/
else
        cp -Rf /Users/jenkins/build_re/develop/phonegap-plugins /Users/jenkins/git/product/build/build/
fi
cd /Users/jenkins/git/product/build
echo "{}" > /Users/jenkins/git/product/build/meta.json
#node index.js --platform=ios --config=/Users/jenkins/git/targets --from=/Users/jenkins/git/product/build --prefix=$BRANCH- --epubs=/Users/jenkins/irls-re
BUILD_DATE=$(date)
node index.js --platform=ios --workspace=/Users/jenkins/git/product --prefix=$BRANCH- --epubs=/Users/jenkins/irls-reader-current-epubs --buildnumber="user

if [ $? -eq 0 ]
then
        echo "command 'node index.js --platform=ios...' successful :-)"
else
        echo "command 'node index.js --platform=ios...' failed :-("
        exit 1
fi

echo ""
echo "Good news, username!"
echo "The xcode-project will be located at the following path: "
echo /Users/jenkins/git/product/build/out/dest/platforms/ios/$BRANCH-$BRAND\_Reader-$TARGETNAME.xcodeproj
echo ""

