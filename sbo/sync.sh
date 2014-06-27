#!/bin/sh

VERSION="14.1"

rsync -av --delete \
	--exclude '.sync.sh' \
	--exclude 'sync.sh' \
	--exclude '.sb_dupes_req' \
	--exclude 'sb_dupes_req' \
	--exclude 'SBoEXCLUDE' \
	rsync://slackbuilds.org/slackbuilds/$VERSION/ \
	/var/www/vhosts/salix.enialis.net/pages/sbo/$VERSION

# use the hidden file only when a non-hidden file is not there
if [ -x ./sb_dupes_req ]; then
	./sb_dupes_req
else
	./.sb_dupes_req
fi
mv SLACKBUILDS.TXT.NEW SLACKBUILDS.TXT
cat SLACKBUILDS.TXT | gzip > SLACKBUILDS.TXT.gz

