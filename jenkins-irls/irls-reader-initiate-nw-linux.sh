###
### This script takes the following parameters: 
###  BRANCHNAME 
###  GIT_COMMIT 
###  CURRENT_BUILD 
###  ID 
###  FACET
###
### path to node (because this job working in host dev02.design.isd.dp.ua)
###
export NODE_HOME=/opt/node
export PATH=$PATH:$NODE_HOME/bin/
###
### Variables
###
ARTIFACTS_DIR=/home/jenkins/irls-reader-artifacts
CURRENT_EPUBS=$HOME/irls-reader-current-epubs
BRANCH=$(echo $BRANCHNAME | sed 's/\//-/g' | sed 's/_/-/g')
FACETS=($(echo $FACET))

### Create associative array
deploymentPackageId=($(echo $ID))
declare -A combineArray
for ((x=0; x<${#deploymentPackageId[@]}; x++))
do
	for ((y=0; y<${#FACETS[@]}; y++))
	do
		if [ -n "$(echo "${deploymentPackageId[x]}" | grep "${FACETS[y]}$")" ]; then
			combineArray+=(["${FACETS[y]}"]="${deploymentPackageId[x]}")
		fi
	done
done

###
### Functions
###
function create_deb_package {
	# $1 - it is facet
	# $2 it is architecture of package
	# Variables
	VER="0.0.1"
	ARCH="$2"
	PREFIX=""
	if [ "$ARCH" = "i386" ]; then
		PREFIX="linux32"
	elif [ "$ARCH" = "amd64" ]; then
		PREFIX="linux64"
	else
		exit 1
	fi
	NAME="$BRANCH-reader-$1"
	NAME_VER=$(echo "$NAME"_"$VER")
	NAME_DEB_PKG=$(echo "$NAME_VER"_"$ARCH".deb)
	DATETIME=$(date "+%a, %d %b %Y %T %z")
	mkdir -p $NAME/opt && cd $NAME
	unzip $WORKSPACE/packager/out/dest/$BRANCH-FFA_Reader-$1-$PREFIX-$VER.zip -d opt/$NAME_VER
	cp /home/jenkins/irls-reader-icons/product_logo_*.png opt/$NAME_VER/
	SIZE=$(du -c opt/$NAME_VER | grep total | awk '{print $1}')
	# Checking exist DEBIAN-directory
	if [ -d DEBIAN ]; then
		rm -f DEBIAN/*
	else
		mkdir DEBIAN
	fi
	# Create desktop-file and move in usr/share/applications
	DESKTOP_FILE="$NAME.desktop"
	if [ -f "$DESKTOP_FILE" ]; then
		cat /dev/null > $DESKTOP_FILE
	else
		touch $DESKTOP_FILE
	fi
	printf "[Desktop Entry]\nVersion=$VER\nName=FFA_Reader (branch=$BRANCH, facet=$1)\nGenericName=FFA_Reader\nComment=Immersive Learning System\nExec=/opt/$NAME_VER/dist/app/nw\nTerminal=false\nIcon=$NAME\nType=Application\nCategories=Education;\nTargetEnvironment=Unity\n..." >> $DESKTOP_FILE
	if [ -d usr/share/applications ]; then
		mv $DESKTOP_FILE usr/share/applications/
	else
		mkdir -p usr/share/applications
		mv $DESKTOP_FILE usr/share/applications/
	fi
	# Create postinst script
	DEB_POSTINST="DEBIAN/postinst"
	if [ -f "$DEB_POSTINST" ]; then
	        cat /dev/null > $DEB_POSTINST
	else
	        touch $DEB_POSTINST
	fi
	printf "#!/bin/sh\nset -e\n# Add icons to the system icons\nXDG_ICON_RESOURCE=\"\$(which xdg-icon-resource 2> /dev/null || true)\"\nif [ ! -x \"\$XDG_ICON_RESOURCE\" ]; then\necho \"Error: Could not find xdg-icon-resource\" >&2\n\texit 1\nfi\nfor icon in \"/opt/$NAME_VER/product_logo_\"*.png; do\n\tsize=\"\${icon##*/product_logo_}\"\n\t\"\$XDG_ICON_RESOURCE\" install --size \"\${size%%.png}\" \"\$icon\" \"$NAME\"\ndone\nUPDATE_MENUS=\"\$(which update-menus 2> /dev/null || true)\"\nif [ -x \"\$UPDATE_MENUS\" ]; then\n\tupdate-menus\nfi\nchmod 777 /opt/$NAME_VER/dist/app\nchmod +x /opt/$NAME_VER/dist/app/nw\nsed -i \'$ d\' /usr/share/applications/$DESKTOP_FILE" >> $DEB_POSTINST
	# Create postrm script
	DEB_POSTRM="DEBIAN/postrm"
	if [ -f "$DEB_POSTRM" ]; then
	        cat /dev/null > $DEB_POSTRM
	else
	        touch $DEB_POSTRM
	fi
	printf "#!/bin/sh\nset -e\naction=\"\$1\"\n# Only do complete clean-up on purge.\nif [ \"\$action\" != \"purge\" ] ; then\n\texit 0\nfi\nrm -rf /opt/$NAME_VER/" >> $DEB_POSTRM
	# Create control file
	DEB_CONTROL="DEBIAN/control"
	if [ -f "$DEB_CONTROL" ]; then
	        cat /dev/null > $DEB_CONTROL
	else
	        touch $DEB_CONTROL
	fi
	printf "Source: $NAME\nVersion: $VER\nSection: misc\nPriority: extra\nMaintainer: IRLS Team <irls@isd.dp.ua>\nHomepage: https://irls.isd.dp.ua/$1/$BRANCH/artifacts\nPackage: $NAME\nArchitecture: $ARCH\nInstalled-Size: $SIZE\nDescription: Immersive Reader Learning System.\n" >> $DEB_CONTROL
	# Set "execute" mode for scripts
	chmod 0755 DEBIAN/postinst DEBIAN/postrm
	chmod 0644 DEBIAN/control
	### Create the tar.gz-archives and the deb-package:
	cd DEBIAN/
	fakeroot tar cfz control.tar.gz control postinst postrm
	cd ../
	fakeroot tar cfz data.tar.gz opt usr
	mv DEBIAN/control.tar.gz .
	fakeroot printf "2.0\n" > debian-binary
	fakeroot ar r $NAME_DEB_PKG debian-binary control.tar.gz data.tar.gz
	mv $NAME_DEB_PKG $WORKSPACE/deb/
	cd ../ && rm -rf $NAME
	}


###
### Body (working with all facets exclude only facet named "ocean")
###
function main_loop {
	notmainloop ()
	{
	if [ $(echo "$i" | egrep "ocean$") ]; then
		getAbort()
		{
                	printf "we do not create the deb-file for facet named 'ocean'\n"
		}
		getAbort
		trap 'getAbort; exit' SIGTERM
        else
		if [ ! -d $WORKSPACE/deb ]; then mkdir $WORKSPACE/deb; fi
		### Create deb-package with application version for Linux 32-bit
		cd $WORKSPACE/packager
		time node index.js --platform=linux32 --config=$WORKSPACE/targets --from=$WORKSPACE/client --manifest=$WORKSPACE/client/package.json --prefix=$BRANCH- --epubs=$CURRENT_EPUBS
		create_deb_package $i i386
		# Move deb-package
		ssh jenkins@dev01.isd.dp.ua "
		if [ ! -d $ARTIFACTS_DIR/${combineArray[$i]}/packages/artifacts ]; then
			mkdir -p $ARTIFACTS_DIR/${combineArray[$i]}/packages/artifacts
		fi
		"
		time scp $WORKSPACE/deb/$NAME_DEB_PKG jenkins@dev01.isd.dp.ua:$ARTIFACTS_DIR/${combineArray[$i]}/packages/artifacts/ && rm -f $WORKSPACE/deb/$NAME_DEB_PKG 
		### Create deb-package with application version for Linux 64-bit
		cd $WORKSPACE/packager
		time node index.js --platform=linux64 --config=$WORKSPACE/targets --from=$WORKSPACE/client --manifest=$WORKSPACE/client/package.json --prefix=$BRANCH- --epubs=$CURRENT_EPUBS
		create_deb_package $i amd64	
		# Move deb-package
		ssh jenkins@dev01.isd.dp.ua "
		if [ ! -d $ARTIFACTS_DIR/${combineArray[$i]}/packages/artifacts ]; then
			mkdir -p $ARTIFACTS_DIR/${combineArray[$i]}/packages/artifacts
		fi
		"
		time scp $WORKSPACE/deb/$NAME_DEB_PKG jenkins@dev01.isd.dp.ua:$ARTIFACTS_DIR/${combineArray[$i]}/packages/artifacts/ && rm -f $WORKSPACE/deb/$NAME_DEB_PKG
		rm -rf $WORKSPACE/deb
	fi
	}
	for i in "${!combineArray[@]}"
	do
		rm -rf $WORKSPACE/*
		#if [ "$i" = "ocean" ]; then BRAND="$i"_"Ocean"; else BRAND="$i"_"FFA"; fi
		if [ "$i" = "epubtest" ]; then BRAND="$i"_"irls"; fi
                GIT_COMMIT_TARGET="$GIT_COMMIT"-"$BRAND"
		cp -Rf $CURRENT_BUILD/$GIT_COMMIT_TARGET/* $WORKSPACE/

		echo $i --- ${combineArray[$i]}
		### Checking contain platform
		#if [ "$BRANCHNAME" = "feature/platforms-config" ]; then
			if grep "platforms.*linux[0-9][0-9]" $WORKSPACE/targets/$BRAND/targetConfig.json; then
				notmainloop
			else
				echo "Shutdown of this job because platform \"linux[0-9][0-9]\" not found in config targetConfig.json"
				exit 0
			fi
		#else
		#	notmainloop
		#fi
	done
}

main_loop
