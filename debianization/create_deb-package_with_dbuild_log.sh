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

root@irls-autotests:~/reader_deb_creating/develop-reader-puddle-0.0.1# cat debian/changelog
develop-reader-puddle (0.0.1) unstable; urgency=low

  * Initial Release.

 -- IRLS Team <irls@isd.dp.ua>  Fri, 20 Jun 2014 10:51:30 +0300


root@irls-autotests:~/reader_deb_creating/develop-reader-puddle-0.0.1# cat debian/compat
8

root@irls-autotests:~/reader_deb_creating/develop-reader-puddle-0.0.1# pwd
/root/reader_deb_creating/develop-reader-puddle-0.0.1
root@irls-autotests:~/reader_deb_creating/develop-reader-puddle-0.0.1# ll
total 84
drwxr-xr-x 2 root root  4096 Jun 20 11:50 debian
drwxr-xr-x 4 root root  4096 Jun 19 15:40 develop-reader-puddle_0.0.1
-rw-r--r-- 1 root root   468 Jun 19 16:58 develop-reader-puddle.desktop
-rw-r--r-- 1 root root   252 Jun 19 16:18 develop-reader-puddle.menu
-rw-r--r-- 1 root root 12050 Jun 19 15:30 product_logo_128.png
-rw-r--r-- 1 root root  6944 Jun 19 15:30 product_logo_16.png
-rw-r--r-- 1 root root  7195 Jun 19 15:30 product_logo_22.png
-rw-r--r-- 1 root root  7241 Jun 19 15:30 product_logo_24.png
-rw-r--r-- 1 root root  7583 Jun 19 15:30 product_logo_32.png
-rw-r--r-- 1 root root  8290 Jun 19 15:30 product_logo_48.png
-rw-r--r-- 1 root root  8981 Jun 19 15:30 product_logo_64.png
root@irls-autotests:~/reader_deb_creating/develop-reader-puddle-0.0.1# ll debian/
total 28
-rw-r--r-- 1 root root 139 Jun 20 10:51 changelog
-rw-r--r-- 1 root root   2 Jun 20 10:51 compat
-rw-r--r-- 1 root root 491 Jun 20 11:24 control
-rw-r--r-- 1 root root 208 Jun 20 10:51 install
-rw-r--r-- 1 root root 699 Jun 20 10:51 postinst
-rw-r--r-- 1 root root 159 Jun 20 10:51 postrm
-rwxr-xr-x 1 root root 456 Jun 20 10:55 rules

root@irls-autotests:~/reader_deb_creating/develop-reader-puddle-0.0.1# debuild -b -us -uc
