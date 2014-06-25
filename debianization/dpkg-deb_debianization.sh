#!/bin/bash

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
# Variables
ARCH_AMD64="amd64"
ARCH_I386="i386"
VER="0.0.1"
NAME="$BRANCH-reader-$FACET"
NAME_VER=$(echo "$NAME"_"$VER")
DATETIME=$(date "+%a, %d %b %Y %T %z")
SIZE=$(du -bc opt/$NAME_VER | grep total | awk '{print $1}')

# Checking exist DEBIAN-directory
if [ -d DEBIAN ]; then
	rm -f DEBIAN/*
else
	mkdir DEBIAN
fi

###
### unzip $BRANCH-FFA_Reader-$FACET-linux64-0.0.1.zip -d $NAME/opt/$NAME_VER
###

# Create desktop-file and move in usr/share/application
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
if [ -d usr/share/application ]; then
	mv $DESKTOP_FILE usr/share/application/
else
	mkdir -p usr/share/application
	mv $DESKTOP_FILE usr/share/application/
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

# Create debian/control file
DEB_CONTROL="debian/control"
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
Architecture: $ARCH_AMD64
Installed-Size: $SIZE
Description: Immersive Learning System Reader
 Immersive Learning System Reader developed by IRLS Team" >> $DEB_CONTROL

# Create changelog file
DEB_CHANGELOG="DEBIAN/changelog"
if [ -f "$DEB_CHANGELOG" ]; then
        cat /dev/null > $DEB_CHANGELOG
else
        touch $DEB_CHANGELOG
fi
printf "$NAME ($VER) unstable; urgency=low

  * Initial Release.

 -- IRLS Team <irls@isd.dp.ua>  $DATETIME" >> $DEB_CHANGELOG

# Create compat file
DEB_COMPAT="DEBIAN/compat"
if [ -f "$DEB_COMPAT" ]; then
        cat /dev/null > $DEB_COMPAT
else
        touch $DEB_COMPAT
fi
printf "8" >> $DEB_COMPAT

###
### dpkg-deb --build $NAME
### mv $NAME.deb $NAME_VER_$ARCH_AMD64.deb
###
