#!/bin/sh

export LANG=C

if [ -f ~/.metagen.lock ];then
	echo "Another metagen.sh instance seems to be running!"
	echo "Check with ps and remove the ~/.metagen.lock file if it is leftover somehow."
	exit 1
else
	touch ~/.metagen.lock
fi

function forcedkill {
	echo "Aborting..."
	rm ~/.metagen.lock
	exit 0
}

# catch SIGINT and SIGTERM, remove metagen.lock file
trap 'forcedkill' 1 2 3 15

function gen_packages_txt {
	echo '' > PACKAGES.TXT
	find ./salix -type f -name '*.meta' -exec cat {} \; >> PACKAGES.TXT

	# Make sure alternative packages are always specified as deps
	# cxxlibs
	sed -i |
	"s/^gcc-g/cxxlibs|gcc-g/" \
	PACKAGES.TXT
	sed -i |
	"s/,gcc-g/,cxxlibs|gcc-g/" \
	PACKAGES.TXT
	# openssl
	sed -i |
	"s/^openssl,/openssl-solibs|openssl,/" \
	PACKAGES.TXT
	sed -i |
	"s/,openssl,/,openssl-solibs|openssl,/" \
	PACKAGES.TXT
	sed -i |
	"s/,openssl$/,openssl-solibs|openssl/" \
	PACKAGES.TXT
	sed -i |
	"s/^openssl$/openssl-solibs|openssl/" \
	PACKAGES.TXT

	# Prefer the solibs packages if none is installed
	sed -i \
	"s/seamonkey|seamonkey-solibs/seamonkey-solibs|seamonkey/" \
	PACKAGES.TXT
	sed -i \
	"s/glibc|glibc-solibs/glibc-solibs|glibc/" \
	PACKAGES.TXT
	sed -i \
	"s/openssl|openssl-solibs/openssl-solibs|openssl/" \
	PACKAGES.TXT

	cat PACKAGES.TXT | gzip -9 -c - > PACKAGES.TXT.gz
}

function gen_meta {
	unset REQUIRED CONFLICTS SUGGESTS
	if [ ! -f $1 ]; then
		echo "File not found: $1"
		exit 1;
	fi
		if [ "`echo $1|grep -E '(.*{1,})\-(.*[\.\-].*[\.\-].*).t[glx]z[ ]{0,}$'`" == "" ]; then
			return;
		fi
	NAME=$(echo $1|sed -re "s/(.*\/)(.*.t[glx]z)$/\2/")
	LOCATION=$(echo $1|sed -re "s/(.*)\/(.*.t[glx]z)$/\1/")
	if [[ `echo $1 | grep "tgz$"` ]]; then
		SIZE=$( expr `gunzip -l $1 |tail -1|awk '{print $1}'` / 1024 )
		USIZE=$( expr `gunzip -l $1 |tail -1|awk '{print $2}'` / 1024 )
	elif [[ `echo $1 | grep "t[lx]z$"` ]]; then
		SIZE=$( expr `ls -l $1 | awk '{print $5}'` / 1024 )
		#USIZE is only an appoximation, nothing similar to gunzip -l for lzma yet
		USIZE=$[$SIZE * 4 ]
	fi
	
	METAFILE=${NAME%t[glx]z}meta
	
	if test -f $LOCATION/${NAME%t[glx]z}dep
	then
		REQUIRED="`cat $LOCATION/${NAME%t[glx]z}dep`"
	fi
	if test -f $LOCATION/${NAME%t[glx]z}con
	then
		CONFLICTS="`cat $LOCATION/${NAME%t[glx]z}con`"
	fi
	if test -f $LOCATION/${NAME%t[glx]z}sug
	then
		SUGGESTS="`cat $LOCATION/${NAME%t[glx]z}sug`"
	fi
	echo "PACKAGE NAME:  $NAME" > $LOCATION/$METAFILE
	if [ -n "$DL_URL" ]; then
		echo "PACKAGE MIRROR:  $DL_URL" >> $LOCATION/$METAFILE
	fi
	echo "PACKAGE LOCATION:  $LOCATION" >> $LOCATION/$METAFILE
	echo "PACKAGE SIZE (compressed):  $SIZE K" >> $LOCATION/$METAFILE
	echo "PACKAGE SIZE (uncompressed):  $USIZE K" >> $LOCATION/$METAFILE
	echo "PACKAGE REQUIRED:  $REQUIRED" >> $LOCATION/$METAFILE
	echo "PACKAGE CONFLICTS:  $CONFLICTS" >> $LOCATION/$METAFILE
	echo "PACKAGE SUGGESTS:  $SUGGESTS" >> $LOCATION/$METAFILE
	echo "PACKAGE DESCRIPTION:" >> $LOCATION/$METAFILE
	if test -f $LOCATION/${NAME%t[glx]z}txt
	then
		cat $LOCATION/${NAME%t[glx]z}txt |grep -E '[^[:space:]]*\:'|grep -v '^#' >> $LOCATION/$METAFILE
	else
		if [[ `echo $1 | grep "tgz$"` ]]; then
			tar xfO $1 install/slack-desc |grep -E '[^[:space:]]*\:'|grep -v '^#' >> $LOCATION/$METAFILE
			tar xfO $1 install/slack-desc |grep -E '[^[:space:]]*\:'|grep -v '^#' > $LOCATION/${NAME%t[glx]z}txt
		elif [[ `echo $1 | grep "txz$"` ]]; then
			xz -c -d $1 | tar xO install/slack-desc |grep -E '[^[:space:]]*\:'|grep -v '^#' >> $LOCATION/$METAFILE
			xz -c -d $1 | tar xO install/slack-desc |grep -E '[^[:space:]]*\:'|grep -v '^#' > $LOCATION/${NAME%t[glx]z}txt
		elif [[ `echo $1 | grep "tlz$"` ]]; then
			lzma -c -d $1 | tar xO install/slack-desc |grep -E '[^[:space:]]*\:'|grep -v '^#' >> $LOCATION/$METAFILE
			lzma -c -d $1 | tar xO install/slack-desc |grep -E '[^[:space:]]*\:'|grep -v '^#' > $LOCATION/${NAME%t[glx]z}txt
		fi
	fi
	echo "" >> $LOCATION/$METAFILE
}


function gen_rss {
	RSSFILE=rss-packages.xml

	SALIXVER=$( basename `pwd` )

	echo "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>
<rss version=\"2.0\">
<channel>
<title>Salix $SALIXVER packages</title>
<link>http://www.salixos.org</link>
<description>Salix $SALIXVER package ChangeLog</description>
<language>en-us</language>

<image>
<title>Salix - The Bonsai OS</title>
<url>http://www.salixos.org</url>
<link>http://www.salixos.org</link>
<width>64</width>
<height>64</height>
</image>
" > $RSSFILE

	sed ':a;N;$!ba;s/\n  / /g' ChangeLog.txt | \
	grep "^a/\|^ap/\|^d/\|^f\|^games\|^gnome\|^kde\|^l/\|^locale/\|^n/\|^n/\|^x/\|^xap/" |\
	sed "s|^\(.*\)/\(.*\)\(\.t[gxbl]z\):\(.*\)|<item>\n<title>\2</title>\n<description>\n\1/\2\3:\4\n</description>\n</item>\n|" \
	>> $RSSFILE
	echo -e "</channel>\n</rss>\n" >> $RSSFILE

	# replace characters that are illegal in xml
	sed -i "s/&/\&amp;/g" $RSSFILE
	sed -i "s/'/\&apos;/g" $RSSFILE
	# replace all instances of ", < or > with &quot;, &gt; and &lt;
	#respectively, but not in tags!
	sed -i '/<?xml \|<rss /!s/"/\&quot;/g' $RSSFILE
	sed -i '/<?xml \|<image>\|<\/image>\|<url>\|<\/url>\|<width>\|<\/width>\|<height>\|<\/height>\|<item>\|<\/item>\|<rss \|<\/rss>\|<language>\|<\/language>\|<channel>\|<\/channel>\|<title>\|<\/title>\|<link>\|<\/link>\|<description>\|<\/description>\|<languages>\|<\/languages>/!s/>/\&gt;/g' $RSSFILE
	sed -i '/<?xml \|<image>\|<\/image>\|<url>\|<\/url>\|<width>\|<\/width>\|<height>\|<\/height>\|<item>\|<\/item>\|<rss \|<\/rss>\|<language>\|<\/language>\|<channel>\|<\/channel>\|<title>\|<\/title>\|<link>\|<\/link>\|<description>\|<\/description>\|<languages>\|<\/languages>/!s/</\&lt;/g' $RSSFILE
}

case "$1" in
	pkg)
		if [ -n "$2" ]; then
			gen_meta $2
		else
			echo "$0 [pkg [file]|all|new|PACKAGESTXT|md5]"
		fi
	;;
	all)
		for pkg in `find ./salix -type f -name '*.t[glx]z' -print`
		do
			gen_meta $pkg
		done
		#$0 PACKAGESTXT
		gen_packages_txt
		gen_rss
	;;
	new)
		for pkg in `find ./salix -type f -name '*.t[glx]z' -print`
		do
			if [ ! -f ${pkg%t[glx]z}meta ]; then
				gen_meta $pkg
			fi
		done
		#$0 PACKAGESTXT
		gen_packages_txt
		gen_rss
	;;
	PACKAGESTXT)
		gen_packages_txt
	;;
	md5)
		echo '' > CHECKSUMS.md5
		for pkg in `find ./salix -type f -name '*.t[glx]z' -print`
		do
			if [ ! -f ${pkg%t[glx]z}md5 ]; then
				md5sum ${pkg} | sed "s|  \.\(.*\)/\(.*\)|  \2|" > ${pkg%t[glx]z}md5
			fi
			cat ${pkg%t[glx]z}md5 | sed "s|`basename ${pkg}`|${pkg}|" >> CHECKSUMS.md5
		done
		cat CHECKSUMS.md5 | gzip -9 -c - > CHECKSUMS.md5.gz
		rm -f CHECKSUMS.md5.gz.asc
		gpg -sba CHECKSUMS.md5.gz
	;;
	rss)
		gen_rss
	;;
	*)
		echo "$0 [pkg [file]|all|new|PACKAGESTXT|md5|rss]"
		echo "$0 [miss|provide] pattern"
	;;
esac

rm ~/.metagen.lock

