#!/bin/bash
# a script to build testing packages from  https://github.com/intevation
# specific to Intevation's infrastructure
#
# USAGE:
# to be executed as user on a docker server
# the $buildtmp directory must be non-existing
#
# if there is a directory "ripe" in the working directory where calling the
# script, the last dated dir will be copied over to the $buildtmp/ripe dir
#
# By default all packages will be built, cf. DEFAULT_PKGS below.
#
# By setting the environment variable IMQ_BUILD_PACKAGES to a
# whitespace seperated list of package names the set of packages to
# build can be customized.
#
# By setting the environment variable IMQ_BUILD_RELEASE to "yes"
# release packages can be build (in contrast to development snapshot
# build).

DEFAULT_PKGS=(
  intelmq-certbund-contact
  intelmq-fody
  intelmq-fody-backend
  intelmq-mailgen
  intelmq-webinput-csv
  )
# Obtain directory of this script to have the base path for docekrfiles.
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

IMQ_BUILD_PACKAGES=${IMQ_BUILD_PACKAGES:-${DEFAULT_PKGS[*]}}
IMQ_BUILD_RELEASE=${IMQ_BUILD_RELEASE:-no}
IMQ_BUILD_DIR=${IMQ_BUILD_DIR:-build-tmp}

# Check if images for building packages exist.
BASE_IMG=`docker images | grep "intelmq-base" | awk '{print $1}'`
if [ -z "$BASE_IMG" ] ; then
  docker build -t intelmq-base:focal -f $SCRIPT_DIR/intelmq-base/Dockerfile $SCRIPT_DIR/intelmq-base
fi
PKG_IMG=`docker images | grep "intelmq-packaging" | awk '{print $1}'`
if [ -z "$PKG_IMG" ] ; then
  docker build -t intelmq-packaging:focal -f $SCRIPT_DIR/intelmq-packaging/Dockerfile $SCRIPT_DIR/intelmq-packaging
fi

#name of the docker container
DC=${LOGNAME}.intelmqpackaging-tmp

#directory to use for git checkouts and resulting packages
buildtmp=${HOME}/${IMQ_BUILD_DIR}

# setup git checkout and right branch
mkdir $buildtmp || { echo "Try (re)moving $buildtmp first" ; exit 1 ; }
pushd $buildtmp

declare -A CO_VERSION
CO_VERSION=(
  [intelmq]=${IMQ_BUILD_VERSION:-"integrated"}
  [intelmq-manager]=${IMQ_BUILD_MANAGER_VERSION:-"deb-packaging"}
  [intelmq-fody]=${IMQ_BUILD_FODY_VERSION:-"master"}
  [intelmq-fody-backend]=${IMQ_BUILD_FODY_BACKEND_VERSION:-"master"}
  [intelmq-mailgen]=${IMQ_BUILD_MAILGEN_VERSION:-"master"}
  [intelmq-certbund-contact]=${IMQ_BUILD_CERTBUND_CONTACT_VERSION:-"master"}
  [intelmq-webinput-csv]=${IMQ_BUILD_WEBINPUT_CSV_VERSION:-"master"}
  )

for repo in $IMQ_BUILD_PACKAGES ; do
  git clone -n --no-single-branch https://github.com/intevation/$repo
  git -C "$repo" checkout --detach ${CO_VERSION[$repo]}
done

# copy a downloaded ripe database to dir 'ripe' if there is one in calling dir
popd
ripeexport=`ls -d ripe/2???-??-?? 2>/dev/null | tail -1`
if [ -d "$ripeexport" ] ; then
    mkdir "$buildtmp/ripe"
    echo cp -a "$ripeexport" "$buildtmp/ripe"
    cp -a "$ripeexport" "$buildtmp/ripe"
fi
pushd "$buildtmp"

# FIXME: Could not find a good way to run the Docker CMD add-host-user command
# and an additional script with the rights of the freshly created user.
# Thus I'm using a plain chown at the end to adjust rights to that
# of the calling user from the docker host on the attached volume.
# Record of what was **not working**:
# a) calling add-host-user from doit.sh and then su - \${LOGNAME}
# b) using su - ${LOGNAME} -c ". /build-pkg/doit.sh" as docker run command
# 20160805 BER

if [ "${IMQ_BUILD_RELEASE,,}" == "yes" ] ; then
    setupcmd="true"
else
  setupcmd="make-testdeb ."
fi
cat >doit.sh<< EOF
cd /build-pkg
trap "chown -R \${HOST_UID}.\${HOST_UID} /build-pkg" EXIT

for i in $IMQ_BUILD_PACKAGES ; do
  echo Building \$i
  cd \$i
  if [ "$setupcmd" ] ; then
    $setupcmd || exit
  fi
  dpkg-buildpackage -us -uc || exit
  cd ..
done

EOF

# create docker container and run all commands
date > docker-run.log
{ docker run  --name ${DC} \
        --env=HOST_UID=$(id -u) --env=HOST_USERNAME=${LOGNAME} \
        --volume=${buildtmp}:/build-pkg/ \
        intelmq-packaging:focal \
        bash -x /build-pkg/doit.sh 2>&1 | tee -a docker-run.log ; } \
    || exit 1
exit_code_docker=${PIPESTATUS[0]}

# remove container
sleep 2
docker rm ${DC}

echo
if (($exit_code_docker)); then
  echo -n "Build failed! "
else
  echo -n "Build successful. "
fi

echo Find results including logs in temporary directory:
echo pushd $buildtmp
popd

exit $exit_code_docker
