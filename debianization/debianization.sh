#!/bin/bash

BRANCH=$1
FACET=$2
VER="0.0.1"
NAME="$BRANCH-reader-$FACET"
NAME_VER=$(echo "$NAME"_"$VER")
DATETIME=$(date "+%a, %d %b %Y %T %z")

###
### mkdir -p ./reader_deb_creating/$NAME-$VER/debian && cd $NAME-$VER
### cp -Rf /home/jenkins/reader_icons/product_logo_*.png .
### unzip ../$BRANCH-FFA_Reader-$FACET-linux64-0.0.1.zip -d $NAME_VER
###

# Create desktop-file
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

# Create menu-file
MENU_FILE="$NAME.menu"
if [ -f "$MENU_FILE" ]; then
	cat /dev/null > $MENU_FILE
else
	touch $MENU_FILE
fi
printf "[Desktop Entry]
?package($NAME):needs=\"x11\" \
  section=\"Education\" \
  hints=\"Immersive Learning System\" \
  title=\"FFA_Reader\" \
  icon=\"/opt/$NAME_VER/product_logo_32.png\" \
  command=\"/opt/$NAME_VER/dist/app/nw\"" >> $MENU_FILE

# Create debian/install file
DEB_INSTALL="debian/install"
if [ -f "$DEB_INSTALL" ]; then
        cat /dev/null > $DEB_INSTALL
else
        touch $DEB_INSTALL
fi
printf "$NAME_VER/* opt/$NAME_VER
$DESKTOP_FILE usr/share/applications
product_logo_*.png opt/$NAME_VER
$MENU_FILE usr/share/menu" >> $DEB_INSTALL

# Create debian/postinst file
DEB_POSTINST="debian/postinst"
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


# Create debian/postrm file
DEB_POSTRM="debian/postrm"
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


# Create debian/rules file
DEB_RULES="debian/rules"
if [ -f "$DEB_RULES" ]; then
        cat /dev/null > $DEB_RULES
else
        touch $DEB_RULES
fi
printf "#!/usr/bin/make -f
%%:
	dh \$@ --with python2" >> $DEB_RULES


# Create debian/control file
DEB_CONTROL="debian/control"
if [ -f "$DEB_CONTROL" ]; then
        cat /dev/null > $DEB_CONTROL
else
        touch $DEB_CONTROL
fi
printf "Source: $NAME
Section: misc
Priority: extra
Maintainer: IRLS Team irls@isd.dp.ua
Build-Depends: debhelper (>= 8.0.0)
Standards-Version: 3.9.4
Homepage: https://irls.isd.dp.ua/$FACET/$BRANCH/artifacts
# it's empty line very important! FUBAR

Package: $NAME
Architecture: any
Depends: \${shlibs:Depends}, \${misc:Depends}
Description: Immersive Learning System Reader
 Immersive Learning System Reader developed by IRLS Team" >> $DEB_CONTROL

# Create debian/changelog file
DEB_CHANGELOG="debian/changelog"
if [ -f "$DEB_CHANGELOG" ]; then
        cat /dev/null > $DEB_CHANGELOG
else
        touch $DEB_CHANGELOG
fi
printf "$NAME ($VER) unstable; urgency=low

  * Initial Release.

 -- IRLS Team <irls@isd.dp.ua>  $DATETIME" >> $DEB_CHANGELOG


# Create debian/compat file
DEB_COMPAT="debian/compat"
if [ -f "$DEB_COMPAT" ]; then
        cat /dev/null > $DEB_COMPAT
else
        touch $DEB_COMPAT
fi
printf "8" >> $DEB_COMPAT

###
### debuild -b -us -uc
###
