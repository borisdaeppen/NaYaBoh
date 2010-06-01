#!/bin/sh

# this is just as unofficial helper
# DON'T use it!
# it works only if you have ssh connection to gna.org
# create a directory gna.org, checkout trunk and website,
# then run this to push the latest git code to Gna!

cp -rv COPYING debian documentation makeDebHere.sh README gna.org/nayaboh
cd gna.org/nayaboh
svn add *
svn commit
cd ../..

sleep 1

cp -v documentation/website/index.html gna.org/website/
cd gna.org/website
svn commit
