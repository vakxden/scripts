root@irls-autotests:~/reader_deb_creating# pwd
/root/reader_deb_creating

root@irls-autotests:~/reader_deb_creating# ll master-reader-puddle/
drwxr-xr-x 2 root root 4096 Jun 25 10:46 DEBIAN
drwxr-xr-x 3 root root 4096 Jun 25 10:47 opt
drwxr-xr-x 3 root root 4096 Jun 25 09:55 usr

root@irls-autotests:~/reader_deb_creating# cat master-reader-puddle/DEBIAN/changelog
master-reader-puddle (0.0.1) unstable; urgency=low

  * Initial Release.

 -- IRLS Team <irls@isd.dp.ua>  Tue, 24 Jun 2014 14:56:34 +0300

root@irls-autotests:~/reader_deb_creating# cat master-reader-puddle/DEBIAN/compat
8

root@irls-autotests:~/reader_deb_creating# cat master-reader-puddle/DEBIAN/control
Source: master-reader-puddle
Version: 0.0.1
Section: misc
Priority: extra
Maintainer: IRLS Team <irls@isd.dp.ua>
Homepage: https://irls.isd.dp.ua/puddle/master/artifacts
Package: master-reader-puddle
Architecture: amd64
Installed-Size: 135820972
Description: Immersive Learning System Reader
 Immersive Learning System Reader developed by IRLS Team

root@irls-autotests:~/reader_deb_creating# cat master-reader-puddle/DEBIAN/copyright
Format: http://www.debian.org/doc/packaging-manuals/copyright-format/1.0/
Upstream-Name: master-reader-puddle
Source: https://irls.isd.dp.ua/puddle/master/artifacts

Files: *
Copyright: 2014 IRLS Team irls@isd.dp.ua
License: GPL-3.0+

Files: debian/*
Copyright: 2014 IRLS Team irls@isd.dp.ua
License: GPL-3.0+

License: GPL-3.0+
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 .
 This package is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 .
 You should have received a copy of the GNU General Public License
 along with this program. If not, see <http://www.gnu.org/licenses/>.
 .
 On Debian systems, the complete text of the GNU General
 Public License version 3 can be found in /usr/share/common-licenses/GPL-3.

# Please also look if there are files or directories which have a
# different copyright/license attached and list them here.
# Please avoid to pick license terms that are more restrictive than the
# packaged work, as it may make Debian's contributions unacceptable upstream.root@irls-autotests:~/reader_deb_creating# cat master-reader-puddle/DEBIAN/install
master-reader-puddle_0.0.1/* opt/master-reader-puddle_0.0.1
master-reader-puddle.desktop usr/share/applications
product_logo_*.png opt/master-reader-puddle_0.0.1
master-reader-puddle.menu usr/share/menu

root@irls-autotests:~/reader_deb_creating# cat master-reader-puddle/DEBIAN/postinst
#!/bin/sh
set -e
# Add icons to the system icons
XDG_ICON_RESOURCE="$(which xdg-icon-resource 2> /dev/null || true)"
if [ ! -x "$XDG_ICON_RESOURCE" ]; then
  echo "Error: Could not find xdg-icon-resource" >&2
  exit 1
fi
for icon in "/opt/master-reader-puddle_0.0.1/product_logo_"*.png; do
        size="${icon##*/product_logo_}"
        "$XDG_ICON_RESOURCE" install --size "${size%.png}" "$icon" "master-reader-puddle"
done
UPDATE_MENUS="$(which update-menus 2> /dev/null || true)"
if [ -x "$UPDATE_MENUS" ]; then
  update-menus
fi
chmod 777 /opt/master-reader-puddle_0.0.1/dist/app
chmod +x /opt/master-reader-puddle_0.0.1/dist/app/nw
sed -i '$ d' /usr/share/applications/master-reader-puddle.desktop

root@irls-autotests:~/reader_deb_creating# cat master-reader-puddle/DEBIAN/postrm
#!/bin/sh
set -e
action="$1"
# Only do complete clean-up on purge.
if [ "$action" != "purge" ] ; then
  exit 0
fi
rm -rf /opt/master-reader-puddle_0.0.1/
