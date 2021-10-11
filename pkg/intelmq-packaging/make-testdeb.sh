#!/bin/bash

TMP=$(mktemp)
TIMESTAMP="$(date +%Y%m%d%H%M%S)"

usage() {
  cat << EOF
Usage: $0 PATH_TO_SRC
EOF
}

fatal()
{
  echo -e "\e[1;31mFATAL: $1\e[0m" >&2
  echo
  usage
  exit 23
}

clean_up () {
  rm $TMP
  exit
}

format_changelog_entry () {
  # Add testbuild tag to version in changelog header
  local HEADER=$(head -1 debian/changelog |
  sed "s/testbuild[0-9]\{14\})/)/; s/)/testbuild${TIMESTAMP})/")
  # Get git revision
  if which git > /dev/null ; then
    local REF=$(git rev-parse HEAD)
  else
    local BRANCH=$(cut -d' ' -f2 .git/HEAD)
    local REF=$(cat .git/${BRANCH})
  fi
  # Format the changelog entry
  cat << EOF
$HEADER

  * Test build of $REF
    by $LOGNAME on $(hostname)

 -- Test Build <no-reply@intevation.de>  $(date -R)

EOF
}

trap clean_up SIGHUP SIGINT SIGTERM

if [ $# -ne 1 ]; then
  fatal "Wrong number of arguments."
  exit 2
fi

test -d "$1" || fatal "$DIR does not exist."

cd "$1"

format_changelog_entry > $TMP
cat debian/changelog  >> $TMP
cp $TMP debian/changelog

cat << EOF

To build a package:

  cd $1
  dpkg-buildpackage -us -uc
  quilt pop -a              # (optional)

Do not commit the temporary changelog entry!
EOF

clean_up

# vim :set noet sts=0 sw=2 ts=8:
