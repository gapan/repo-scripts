#!/bin/sh

VERSION="14.1"

DIR="./"

rsync -av --delete \
	--exclude '.sync.sh' \
	--exclude 'sync.sh' \
	--exclude '.sb_dupes_req' \
	--exclude 'sb_dupes_req' \
	--exclude 'SBoEXCLUDE' \
	--exclude '.sb_adddeps' \
	--exclude 'sb_adddeps' \
	--exclude 'SBoADD' \
	--exclude '.sb_replace' \
	--exclude 'sb_replace' \
	--exclude 'SBoREPLACE' \
	--exclude 'SLACKBUILDS.TXT' \
	--exclude 'SLACKBUILDS.TXT.gz' \
	rsync://slackbuilds.org/slackbuilds/$VERSION/ \
	$DIR

rsync -av \
	rsync://slackbuilds.org/slackbuilds/$VERSION/SLACKBUILDS.TXT \
	$DIR/SLACKBUILDS.TXT.SBo

# use the hidden file only when a non-hidden file is not there
if [ -x ./sb_dupes_req ]; then
	./sb_dupes_req
else
	./.sb_dupes_req
fi
mv SLACKBUILDS.TXT.SBo.NEW SLACKBUILDS.TXT.SBo
if [ -x ./sb_adddeps ]; then
	./sb_adddeps
else
	./.sb_adddeps
fi
mv SLACKBUILDS.TXT.SBo.NEW SLACKBUILDS.TXT.SBo
if [ -x ./sb_replace ]; then
	./sb_replace
else
	./.sb_replace
fi
rm -f SLACKBUILDS.TXT.SBo

# put '%README%' dependencies at the end of the REQUIRES lines
sed -i "s/REQUIRES: \(.*\)%README%,\(.*\)/REQUIRES: \1\2,%README/" \
	SLACKBUILDS.TXT.SBo.NEW

mv SLACKBUILDS.TXT.SBo.NEW SLACKBUILDS.TXT
cat SLACKBUILDS.TXT | gzip > SLACKBUILDS.TXT.gz

