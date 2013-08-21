#!/bin/sh

VERSION="14.0"

rsync -av --delete --exclude '.sync.sh' --exclude '.sb_dupes_req' \
	rsync://slackbuilds.org/slackbuilds/$VERSION/ \
	/var/www/vhosts/salix.enialis.net/pages/sbo/$VERSION

./.sb_dupes_req
mv SLACKBUILDS.TXT.NEW SLACKBUILDS.TXT
cat SLACKBUILDS.TXT | gzip > SLACKBUILDS.TXT.gz

