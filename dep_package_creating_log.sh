root@irls-autotests:~/reader_deb_creating# mkdir -p /root/reader_deb_creating/develop-reader-puddle-0.0.1 && cd develop-reader-puddle-0.0.1
root@irls-autotests:~/reader_deb_creating/develop-reader-puddle-0.0.1# cp -Rf /home/dvac/reader_icons/product_logo_*.png .
root@irls-autotests:~/reader_deb_creating/develop-reader-puddle-0.0.1# cp /root/expe_google/usr/share/applications/google-chrome.desktop develop-reader-puddle.desktop
root@irls-autotests:~/reader_deb_creating/develop-reader-puddle-0.0.1# unzip ../develop-FFA_Reader-puddle-linux64-0.0.1.zip -d develop-reader-puddle_0.0.1

root@irls-autotests:~/reader_deb_creating/develop-reader-puddle-0.0.1# cat develop-reader-puddle.desktop
[Desktop Entry]
Version=0.0.1
Name=FFA_Reader (branch=develop, facet=puddle)
# Only KDE 4 seems to use GenericName, so we reuse the KDE strings.
# From Ubuntu's language-pack-kde-XX-base packages, version 9.04-20090413.
GenericName=FFA_Reader
# Gnome and KDE 3 uses Comment.
Comment=Immersive Learning System
Exec=/opt/develop-reader-puddle_0.0.1/dist/app/nw
Terminal=false
Icon=develop-reader-puddle
Type=Application
Categories=Education;
TargetEnvironment=Unity
...

root@irls-autotests:~/reader_deb_creating/develop-reader-puddle-0.0.1# cat develop-reader-puddle.menu
?package(develop-reader-puddle):needs="x11" \
  section="Education" \
  hints="Immersive Learning System" \
  title="FFA_Reader" \
  icon="/opt/develop-reader-puddle_0.0.1/product_logo_32.png" \
  command="/opt/develop-reader-puddle_0.0.1/dist/app/nw"


root@irls-autotests:~/reader_deb_creating/develop-reader-puddle-0.0.1# export DEBFULLNAME="IRLS Team"
root@irls-autotests:~/reader_deb_creating/develop-reader-puddle-0.0.1# yes | dh_make -n -s -e irls@isd.dp.ua
root@irls-autotests:~/reader_deb_creating/develop-reader-puddle-0.0.1# rm -f debian/*.ex debian/*.EX debian/README*

root@irls-autotests:~/reader_deb_creating/develop-reader-puddle-0.0.1# cat debian/install
develop-reader-puddle_0.0.1/* opt/develop-reader-puddle_0.0.1
develop-reader-puddle.desktop usr/share/applications
product_logo_*.png opt/develop-reader-puddle_0.0.1
develop-reader-puddle.menu usr/share/menu

root@irls-autotests:~/reader_deb_creating/develop-reader-puddle-0.0.1# cat debian/postinst
#!/bin/sh
set -e
# Add icons to the system icons
XDG_ICON_RESOURCE="`which xdg-icon-resource 2> /dev/null || true`"
if [ ! -x "$XDG_ICON_RESOURCE" ]; then
  echo "Error: Could not find xdg-icon-resource" >&2
  exit 1
fi
for icon in "/opt/develop-reader-puddle_0.0.1/product_logo_"*.png; do
  size="${icon##*/product_logo_}"
  "$XDG_ICON_RESOURCE" install --size "${size%.png}" "$icon" "develop-reader-puddle"
done
UPDATE_MENUS="`which update-menus 2> /dev/null || true`"
if [ -x "$UPDATE_MENUS" ]; then
  update-menus
fi
chmod 777 /opt/develop-reader-puddle_0.0.1/dist/app
chmod +x /opt/develop-reader-puddle_0.0.1/dist/app/nw
sed -i '$ d' /usr/share/applications/develop-reader-puddle.desktop

root@irls-autotests:~/reader_deb_creating/develop-reader-puddle-0.0.1# cat debian/postrm
#!/bin/sh
set -e
action="$1"
# Only do complete clean-up on purge.
if [ "$action" != "purge" ] ; then
  exit 0
fi
rm -rf /opt/develop-reader-puddle_0.0.1/

root@irls-autotests:~/reader_deb_creating/develop-reader-puddle-0.0.1# cat debian/rules
#!/usr/bin/make -f
%:
        dh $@ --with python2

root@irls-autotests:~/reader_deb_creating/develop-reader-puddle-0.0.1# cat debian/control
### Start of file
Source: develop-reader-puddle
Section: misc
Priority: extra
Maintainer: IRLS Team irls@isd.dp.ua
Build-Depends: debhelper (>= 8.0.0)
Standards-Version: 3.9.4
Homepage: https://irls.isd.dp.ua/puddle/develop/artifacts
# it's empty line very important! FUBAR

Package: develop-reader-puddle
Architecture: any
Depends: ${shlibs:Depends}, ${misc:Depends}
Description: <Immersive Learning System Reader>
 <Immersive Learning System Reader developed by irls-team>
### End of file

root@irls-autotests:~/reader_deb_creating/develop-reader-puddle-0.0.1# debuild -b -us -uc
