#!/bin/bash

###
### Before running this script, you must run the following commands:
###
### mkdir -p $NAME/opt && cd $NAME
### unzip $BRANCH-FFA_Reader-$FACET-linux64-0.0.1.zip -d $NAME/opt/$NAME_VER
### cp /home/dvac/git/scripts/debianization/manual_debianization.sh .
### cp /home/jenkins/irls-reader-icons/product_logo_*.png opt/$NAME_VER/
###
### How to use script:
### ./manual_debianization.sh master puddle amd64
###

# Checking passed variables
BRANCH=$1
if [ -z $BRANCH ]; then
	echo "branch must be passed"
	exit 1
fi
FACET=$2
if [ -z $FACET ]; then
	echo "branch must be passed"
	exit 1
fi
ARCH=$3
if [ -z $ARCH ]; then
	echo "architecture must be passed"
	exit 1
fi
if [ "$ARCH" != "amd64" -a "$ARCH" != "i386" ]; then
	echo "architecture must be amd64 or i386"
	exit 1
fi
# Variables
VER="0.0.1"
NAME="$BRANCH-reader-$FACET"
NAME_VER=$(echo "$NAME"_"$VER")
DATETIME=$(date "+%a, %d %b %Y %T %z")
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
Name=FFA_Reader (branch=$BRANCH, facet=$FACET)
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

# Create postinst file
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

# Create postrm file
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
printf "Source: master-reader-puddle
Version: 0.0.1
Section: misc
Priority: extra
Maintainer: IRLS Team <irls@isd.dp.ua>
Homepage: https://irls.isd.dp.ua/$FACET/$BRANCH/artifacts
Package: $NAME
Architecture: $ARCH
Installed-Size: $SIZE
Description: Immersive Learning System Reader.\n" >> $DEB_CONTROL

# Set "execute" mode for scripts
chmod +x DEBIAN/postinst DEBIAN/postrm

### After running script:
### cd DEBIAN/
### tar cfz control.tar.gz .
### cd ../
### tar cfz data.tar.gz opt usr
### mv DEBIAN/control.tar.gz .
### printf "2.0\n" > debian-binary
### ar r master-reader-puddle_0.0.1_amd64.deb debian-binary control.tar.gz data.tar.gz
###
