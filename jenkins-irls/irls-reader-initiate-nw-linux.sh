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
###
### Body (working with all facets exclude only facet named "ocean")
###
for facet in ${FACETS[@]}
do
        if [ $(echo "$facet" | egrep "ocean$") ]; then
		printf "we can only work with the all facets exclude 'ocean' \n"
	else
		### Remove old version of project and zip-archives
		rm -rf client packager server deb/*.deb
		if [ ! -d deb ]; then mkdir deb; fi
		### Copy project to workspace
		# this line commented because this job was moved to host dev02.design.isd.dp.ua
		#cp -Rf $CURRENT_BUILD/$GIT_COMMIT/* .
		# this line there because this job working in host dev02.design.isd.dp.ua
		cp -Rf $CURRENT_BUILD/* .
		### Create associative array
		deploymentPackageId=($(echo $ID))
		ELEMENT_OF_FACETS=($facet)
		declare -A combineArray
		for ((x=0; x<${#deploymentPackageId[@]}; x++))
		do
			for ((y=0; y<${#ELEMENT_OF_FACETS[@]}; y++))
			do
				if [ -n "$(echo "${deploymentPackageId[x]}" | grep "${ELEMENT_OF_FACETS[y]}$")" ]; then
					combineArray+=(["${ELEMENT_OF_FACETS[y]}"]="${deploymentPackageId[x]}")
				fi
			done
		done
		### Create deb-package with application version for Linux 32-bit
		for i in "${!combineArray[@]}"
		do
			echo $i --- ${combineArray[$i]}
			cd $WORKSPACE/packager
			node index.js --target=linux32 --config=/home/jenkins/build_config --from=$WORKSPACE/client --manifest=$WORKSPACE/client/package.json --prefix=$BRANCH- --suffix=-$i --epubs=$CURRENT_EPUBS/$i
			# Variables
			VER="0.0.1"
			ARCH="i386"
			NAME="$BRANCH-reader-$i"
			NAME_VER=$(echo "$NAME"_"$VER")
			NAME_DEB_PKG=$(echo "$NAME_VER"_"$ARCH".deb)
			DATETIME=$(date "+%a, %d %b %Y %T %z")
			mkdir -p $NAME/opt && cd $NAME
			unzip $WORKSPACE/packager/out/dest/$BRANCH-FFA_Reader-$i-linux32-0.0.1.zip -d opt/$NAME_VER
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
			printf "[Desktop Entry]
			Version=$VER
			Name=FFA_Reader (branch=$BRANCH, facet=$i)
			GenericName=FFA_Reader
			Comment=Immersive Learning System
			Exec=/opt/$NAME_VER/dist/app/nw
			Terminal=false
			Icon=$NAME
			Type=Application
			Categories=Education;
			TargetEnvironment=Unity
			..." >> $DESKTOP_FILE
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
			printf "#!/bin/sh
			set -e
			# Add icons to the system icons
			XDG_ICON_RESOURCE=\"\$(which xdg-icon-resource 2> /dev/null || true)\"
			if [ ! -x \"\$XDG_ICON_RESOURCE\" ]; then
			  echo \"Error: Could not find xdg-icon-resource\" >&2
			  exit 1
			fi
			for icon in \"/opt/$NAME_VER/product_logo_\"*.png; do
				size=\"\${icon##*/product_logo_}\"
				\"\$XDG_ICON_RESOURCE\" install --size \"\${size%%.png}\" \"\$icon\" \"$NAME\"
			done
			UPDATE_MENUS=\"\$(which update-menus 2> /dev/null || true)\"
			if [ -x \"\$UPDATE_MENUS\" ]; then
			  update-menus
			fi
			chmod 777 /opt/$NAME_VER/dist/app
			chmod +x /opt/$NAME_VER/dist/app/nw
			sed -i \'$ d\' /usr/share/applications/$DESKTOP_FILE" >> $DEB_POSTINST

			# Create postrm script
			DEB_POSTRM="DEBIAN/postrm"
			if [ -f "$DEB_POSTRM" ]; then
			        cat /dev/null > $DEB_POSTRM
			else
			        touch $DEB_POSTRM
			fi
			printf "#!/bin/sh
			set -e
			action=\"\$1\"
			# Only do complete clean-up on purge.
			if [ \"\$action\" != \"purge\" ] ; then
			  exit 0
			fi
			rm -rf /opt/$NAME_VER/" >> $DEB_POSTRM
			
			# Create control file
			DEB_CONTROL="DEBIAN/control"
			if [ -f "$DEB_CONTROL" ]; then
			        cat /dev/null > $DEB_CONTROL
			else
			        touch $DEB_CONTROL
			fi
			printf "Source: $NAME
			Version: $VER
			Section: misc
			Priority: extra
			Maintainer: IRLS Team <irls@isd.dp.ua>
			Homepage: https://irls.isd.dp.ua/$i/$BRANCH/artifacts
			Package: $NAME
			Architecture: $ARCH
			Installed-Size: $SIZE
			Description: Immersive Reader Learning System.\n" >> $DEB_CONTROL

			# Set "execute" mode for scripts
			chmod +x DEBIAN/postinst DEBIAN/postrm

			### Create the tar.gz-archives and the deb-package:
			cd DEBIAN/
			tar cfz control.tar.gz control postinst postrm
			cd ../
			tar cfz data.tar.gz opt usr
			mv DEBIAN/control.tar.gz .
			printf "2.0\n" > debian-binary
			ar r $NAME_DEB_PKG debian-binary control.tar.gz data.tar.gz
			mv $NAME_DEB_PKG $WORKSPACE/deb
			cd ../ && rm -rf $NAME
			
			# Move deb-package
			ssh jenkins@dev01.isd.dp.ua "
			if [ ! -d $ARTIFACTS_DIR/${combineArray[$i]}/packages/artifacts ]; then
				mkdir -p $ARTIFACTS_DIR/${combineArray[$i]}/packages/artifacts
			fi
			"
			scp $WORKSPACE/apk/$NAME_DEB_PKG jenkins@dev01.isd.dp.ua:$ARTIFACTS_DIR/${combineArray[$i]}/packages/artifacts/
		done
		
		### Create deb-package with application version for Linux 64-bit
		for i in "${!combineArray[@]}"
		do
			echo $i --- ${combineArray[$i]}
			cd $WORKSPACE/packager
			node index.js --target=linux64 --config=/home/jenkins/build_config --from=$WORKSPACE/client --manifest=$WORKSPACE/client/package.json --prefix=$BRANCH- --suffix=-$i --epubs=$CURRENT_EPUBS/$i
			# Variables
			VER="0.0.1"
			ARCH="amd64"
			NAME="$BRANCH-reader-$i"
			NAME_VER=$(echo "$NAME"_"$VER")
			NAME_DEB_PKG=$(echo "$NAME_VER"_"$ARCH".deb)
			DATETIME=$(date "+%a, %d %b %Y %T %z")
			mkdir -p $NAME/opt && cd $NAME
			unzip $WORKSPACE/packager/out/dest/$BRANCH-FFA_Reader-$i-linux32-0.0.1.zip -d opt/$NAME_VER
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
			printf "[Desktop Entry]
			Version=$VER
			Name=FFA_Reader (branch=$BRANCH, facet=$i)
			GenericName=FFA_Reader
			Comment=Immersive Learning System
			Exec=/opt/$NAME_VER/dist/app/nw
			Terminal=false
			Icon=$NAME
			Type=Application
			Categories=Education;
			TargetEnvironment=Unity
			..." >> $DESKTOP_FILE
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
			printf "#!/bin/sh
			set -e
			# Add icons to the system icons
			XDG_ICON_RESOURCE=\"\$(which xdg-icon-resource 2> /dev/null || true)\"
			if [ ! -x \"\$XDG_ICON_RESOURCE\" ]; then
			  echo \"Error: Could not find xdg-icon-resource\" >&2
			  exit 1
			fi
			for icon in \"/opt/$NAME_VER/product_logo_\"*.png; do
				size=\"\${icon##*/product_logo_}\"
				\"\$XDG_ICON_RESOURCE\" install --size \"\${size%%.png}\" \"\$icon\" \"$NAME\"
			done
			UPDATE_MENUS=\"\$(which update-menus 2> /dev/null || true)\"
			if [ -x \"\$UPDATE_MENUS\" ]; then
			  update-menus
			fi
			chmod 777 /opt/$NAME_VER/dist/app
			chmod +x /opt/$NAME_VER/dist/app/nw
			sed -i \'$ d\' /usr/share/applications/$DESKTOP_FILE" >> $DEB_POSTINST

			# Create postrm script
			DEB_POSTRM="DEBIAN/postrm"
			if [ -f "$DEB_POSTRM" ]; then
			        cat /dev/null > $DEB_POSTRM
			else
			        touch $DEB_POSTRM
			fi
			printf "#!/bin/sh
			set -e
			action=\"\$1\"
			# Only do complete clean-up on purge.
			if [ \"\$action\" != \"purge\" ] ; then
			  exit 0
			fi
			rm -rf /opt/$NAME_VER/" >> $DEB_POSTRM
			
			# Create control file
			DEB_CONTROL="DEBIAN/control"
			if [ -f "$DEB_CONTROL" ]; then
			        cat /dev/null > $DEB_CONTROL
			else
			        touch $DEB_CONTROL
			fi
			printf "Source: $NAME
			Version: $VER
			Section: misc
			Priority: extra
			Maintainer: IRLS Team <irls@isd.dp.ua>
			Homepage: https://irls.isd.dp.ua/$i/$BRANCH/artifacts
			Package: $NAME
			Architecture: $ARCH
			Installed-Size: $SIZE
			Description: Immersive Reader Learning System.\n" >> $DEB_CONTROL

			# Set "execute" mode for scripts
			chmod +x DEBIAN/postinst DEBIAN/postrm

			### Create the tar.gz-archives and the deb-package:
			cd DEBIAN/
			tar cfz control.tar.gz control postinst postrm
			cd ../
			tar cfz data.tar.gz opt usr
			mv DEBIAN/control.tar.gz .
			printf "2.0\n" > debian-binary
			ar r $NAME_DEB_PKG debian-binary control.tar.gz data.tar.gz
			mv $NAME_DEB_PKG $WORKSPACE/deb
			cd ../ && rm -rf $NAME
			
			# Move deb-package
			ssh jenkins@dev01.isd.dp.ua "
			if [ ! -d $ARTIFACTS_DIR/${combineArray[$i]}/packages/artifacts ]; then
				mkdir -p $ARTIFACTS_DIR/${combineArray[$i]}/packages/artifacts
			fi
			"
			scp $WORKSPACE/apk/$NAME_DEB_PKG jenkins@dev01.isd.dp.ua:$ARTIFACTS_DIR/${combineArray[$i]}/packages/artifacts/
		done
	fi
done
