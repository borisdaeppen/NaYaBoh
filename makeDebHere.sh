#!/bin/sh

# Copyright 2010 Boris Daeppen <boris_daeppen@bluewin.ch>
# 
# This file is part of NaYaBoh.
# 
# NaYaBoh is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# NaYaBoh is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with NaYaBoh.  If not, see <http://www.gnu.org/licenses/>.


# remove old packages
rm nayaboh*.deb 2> /dev/null

# pack manpage
cp documentation/manpage/nayaboh*.1 debian/usr/share/man/man1/
gzip --best debian/usr/share/man/man1/nayaboh*.1

#pack changelog
cp changelog debian/usr/share/doc/nayaboh/
cp changelog.Debian debian/usr/share/doc/nayaboh/
gzip --best debian/usr/share/doc/nayaboh/changelog
gzip --best debian/usr/share/doc/nayaboh/changelog.Debian

# update md5sums file of dep-tree
echo "update md5sums file"
rm debian/DEBIAN/md5sums
for i in $( find debian/usr/ -type f ); do
        md5sum $i | sed -e "s/debian\///g" >> debian/DEBIAN/md5sums
done

# renew the size information
sed -i '/Installed-Size/ d' debian/DEBIAN/control # delete
echo "Installed-Size: $(du -s --exclude DEBIAN debian/ | cut -f1)" >> debian/DEBIAN/control

# create deb package
echo "build package"
fakeroot dpkg-deb --build debian \
$( grep Package debian/DEBIAN/control | cut -d" " -f2 )_\
$( grep Version debian/DEBIAN/control | cut -d" " -f2 )_\
$( grep Architecture debian/DEBIAN/control | cut -d" " -f2 )\
.deb

# remove packed things,
# I don't need it in src
rm debian/usr/share/man/man1/nayaboh*.1.gz
rm debian/usr/share/doc/nayaboh/changelog.gz
rm debian/usr/share/doc/nayaboh/changelog.Debian.gz

