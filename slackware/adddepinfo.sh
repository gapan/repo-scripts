#!/bin/sh
#
# adddepinfo.sh
#
# This script adds support for dependencies on Slackware
# repositories. It creates a "ghost" repository that only holds
# the dependency info and diverts all traffic to a real Slackware
# repository.
#
# You will need to have a directory with dependency files named
# "packagename.dep" for each package in the slackware repository. That
# file should include a comma separated list of dependencies.
#
# The script checks if there are any updated packages on the Slackware
# repository. If there are, the PACKAGES.TXT file is created again with
# dependency info from those .dep files.
#
# If you want to force the creation of a new PACKAGES.TXT file, even if
# there are no package updates in the Slackware repository, like if you
# update a .dep file, you can run the script with the "-f" switch.
#
# You can change the SLACKREPO variable to point the traffic to a
# different Slackware repository than the default one.
#
# Written by George Vlahavas <vlahavas~at~gmail~dot~com> for Salix
#
# Licensed under the GPLv3
#

SLACKREPO="http://ftp.gwdg.de/pub/linux/slackware/slackware-13.37/"
#SLACKREPO="ftp://ftp.osuosl.org/pub/slackware/slackware-13.1/"

EXCLUDE=" arts k3b3 kdelibs3 qca-tls1 qca1 qt3 tightvnc "

cd $(dirname $0)
CWD=`pwd`
DEPSDIR="$CWD/deps"

#
# Don't touch anything after this
#

par=$1

update_packages_txt() {
rm -f .CHECKSUMS.md5.new
wget $SLACKREPO/$SUBDIR/CHECKSUMS.md5 -O .CHECKSUMS.md5.new || exit 1

touch CHECKSUMS.md5
if [[ ! `diff CHECKSUMS.md5 .CHECKSUMS.md5.new` = "" ]] || [[ "$par" = "-f" ]] ; then

	rm -f .PACKAGES.TXT.new .PACKAGES.TXT.salix .CHECKSUMS.md5.asc.new ChangeLog.txt
	
	wget $SLACKREPO/$SUBDIR/PACKAGES.TXT -O .PACKAGES.TXT.new || exit 1
	wget $SLACKREPO/$SUBDIR/CHECKSUMS.md5.asc -O .CHECKSUMS.md5.asc.new || exit 1
	wget $SLACKREPO/$SUBDIR/ChangeLog.txt

	echo -n "Adding dependency info to PACKAGES.TXT, this may take a while"

	for i in `grep "PACKAGE NAME:  .*t[gx]z$" .PACKAGES.TXT.new | sed "s/PACKAGE NAME:  //"`;do
		echo -n "."
		PKGNAME=`echo $i | sed "s/\(.*\)-\(.*\)-\(.*\)-\(.*\).t[gx]z/\1/"`
		if [ -f $DEPSDIR/$PKGNAME.dep ]; then
			DEPS=`cat $DEPSDIR/$PKGNAME.dep`
		else
			DEPS=""
		fi
		if [ -f $DEPSDIR/$PKGNAME.con ]; then
		CONFLICTS=`cat $DEPSDIR/$PKGNAME.con`
		else
			CONFLICTS=""
		fi
		if [ -f $DEPSDIR/$PKGNAME.sug ]; then
			SUGGESTS=`cat $DEPSDIR/$PKGNAME.sug`
		else
			SUGGESTS=""
		fi

		if [[ ! $EXCLUDE =~ ".* $PKGNAME .*" ]]; then	
			sed -n -e "/^PACKAGE NAME:  $i/!d" -e '/^.\+$/{h;n}; :a /^.\+$/{H;n;ba};H;x; s/PACKAGE \(MIRROR\|REQUIRED\|CONFLICTS\|SUGGESTS\):[^\n]\+\n//g;' -e "s@\(PACKAGE NAME:[^\n]\+\n\)\(.*PACKAGE SIZE (uncompressed):[^\n]\+\n\)@\1PACKAGE MIRROR: ${SLACKREPO}${REPODIR}\n\2PACKAGE REQUIRED:  $DEPS\nPACKAGE CONFLICTS:  $CONFLICTS\nPACKAGE SUGGESTS:  $SUGGESTS\n@g;p;q" .PACKAGES.TXT.new >> .PACKAGES.TXT.salix
		fi
	done

	# add an extra empty line before every package name, just to be
	# sure
	sed -i "s/^PACKAGE NAME:/\nPACKAGE NAME:/" .PACKAGES.TXT.salix

	# Prefer the solibs packages if none is installed
	sed -i \
	"s/seamonkey|seamonkey-solibs/seamonkey-solibs|seamonkey/" \
	.PACKAGES.TXT.salix
	sed -i \
	"s/glibc|glibc-solibs/glibc-solibs|glibc/" \
	.PACKAGES.TXT.salix
	sed -i \
	"s/openssl|openssl-solibs/openssl-solibs|openssl/" \
	.PACKAGES.TXT.salix
	
	mv -f .PACKAGES.TXT.salix PACKAGES.TXT
	rm -f .PACKAGES.TXT.new
	rm -f PACKAGES.TXT.gz
	cat PACKAGES.TXT | gzip -9 -c - > PACKAGES.TXT.gz
	mv -f .CHECKSUMS.md5.new CHECKSUMS.md5
	mv -f .CHECKSUMS.md5.asc.new CHECKSUMS.md5.asc

	echo ""
else
	echo "No new packages found."
	rm .CHECKSUMS.md5.new
fi
}

SUBDIR=""
REPODIR=""
update_packages_txt

[ ! -d $CWD/patches ] && mkdir $CWD/patches
cd $CWD/patches
SUBDIR="patches"
update_packages_txt

[ ! -d $CWD/extra ] && mkdir $CWD/extra
cd $CWD/extra
SUBDIR="extra"
REPODIR="extra/"
update_packages_txt

cd $CWD

