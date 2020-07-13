#!/bin/sh
set -xe

SPECFILE=$1

err() {
  exitval="$1"
  shift
  echo "$@" > /dev/stderr
  exit $exitval
}

echo "Building \"$1\""
if [ ! -f "$1" ]; then
  err 1 "Spec \"$1\" not found"
fi

shift

CURRENT_DATETIME=`date +'%Y%m%d%H%M%S'`

if [ ! -f "$HOME/.rpmmacros" ]; then
   echo "%_topdir $HOME/rpm/" > $HOME/.rpmmacros
   echo "%_tmppath $HOME/rpm/tmp" >> $HOME/.rpmmacros
   echo "%packager ${PACKAGER}" >> $HOME/.rpmmacros
fi

if [ ! -d "$HOME/rpm" ]; then
  echo "Creating directories need by rpmbuild"
  mkdir -p ~/rpm/{BUILD,RPMS,SOURCES,SRPMS,SPECS,tmp} 2>/dev/null
  mkdir ~/rpm/RPMS/{i386,i586,i686,noarch} 2>/dev/null
fi

RPM_TOPDIR=`rpm --eval '%_topdir'`
BUILDROOT=`rpm --eval '%_tmppath'`
BUILDROOT_TMP="$BUILDROOT/tmp/"
BUILDROOT="$BUILDROOT/tmp/${PACKAGE}"

PACKAGE=luajit-${CURRENT_DATETIME}
[ "$PACKAGE" != "/" ] && [ -d "$PACKAGE" ] && rm -rf "$PACKAGE"

mkdir -p ${RPM_TOPDIR}/{BUILD,RPMS,SOURCES,SRPMS,SPECS}
mkdir -p ${RPM_TOPDIR}/RPMS/{i386,i586,i686,noarch}
mkdir -p $BUILDROOT

(
TEMPDIR="$HOME/rpm/tmp/"
cp -prv . "$TEMPDIR/$PACKAGE"
cd "$TEMPDIR"
tar czf ${RPM_TOPDIR}/SOURCES/luajit-${CURRENT_DATETIME}.tar.gz ${PACKAGE}
[ "$PACKAGE" != "/" ] && rm -rvf "$PACKAGE"
)

VERSION=`cat Makefile | grep -P "^(MAJVER|MINVER|RELVER)" | sed "s/ //g"`
eval $VERSION
COMMIT=`git rev-parse --short HEAD`

MULTILIB=lib
ARCH=`arch`
if [ "$ARCH" == "x86_64" ]
then
	MULTILIB=lib64
fi

rpmbuild -ba --clean $SPECFILE \
  --define "current_datetime ${CURRENT_DATETIME}" \
  --define "version ${MAJVER}.${MINVER}.${RELVER}" \
  --define "release ${COMMIT}" \
  --define "multilib ${MULTILIB}"
