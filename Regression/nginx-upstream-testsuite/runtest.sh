#!/bin/bash
# vim: dict=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /CoreOS/nginx/Regression/nginx-upstream-testsuite
#   Description: Upstream nginx test suite
#   Author: Joe Orton <jorton@redhat.com>
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Copyright (c) 2013 Red Hat, Inc. All rights reserved.
#
#   PROVIDE YOUR LICENSE TEXT HERE.
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Include Beaker environment
. /usr/bin/rhts-environment.sh || exit 1
. /usr/share/beakerlib/beakerlib.sh || exit 1

PACKAGE="nginx"
LOOKASIDE=
TARVERSION=fb366c51eac6
LOOKASIDE=${LOOKASIDE:-http://download.eng.bos.redhat.com/qa/rhts/lookaside/}

TARVERSION=fb366c51eac6
TARSTUB=nginx-tests-${TARVERSION}
TARBALL=${TARSTUB}.tar.gz
TARURL=${LOOKASIDE}/${TARBALL}

PACKAGE="nginx"
SERVICE="nginx"
NGINX=/usr/sbin/nginx

WHITELIST=$PWD/whitelist.txt

if test -d /opt/rh/nginx14; then
    SERVICE=nginx14-nginx
    PACKAGE=nginx14-nginx
    NGINX=/opt/rh/nginx14/root/usr/sbin/nginx
fi

rlJournalStart
    rlPhaseStartSetup
        rlAssertRpm $PACKAGE
        rlRun "TmpDir=\$(mktemp -d)" 0 "Creating tmp directory"
        rlRun "pushd $TmpDir"
        rlRun "wget $TARURL"
        rlRun "tar -xzvf ${TARBALL}"
        rlRun "pushd ${TARSTUB}"
    rlPhaseEnd

    rlPhaseStartTest
        # Uncomment this to run entire test suite:
        #rlRun "TEST_NGINX_BINARY=${NGINX} prove ." 0 "Run whole test suite"
    
        # Run whitelisted tests is known to pass with 1.4.x
        rlRun "TEST_NGINX_BINARY=${NGINX} xargs prove < ${WHITELIST}" 0 "Run test suite w/whitelist"
    rlPhaseEnd

    rlPhaseStartCleanup
        rlRun "popd"
        rlRun "popd"
        rlRun "rm -r $TmpDir" 0 "Removing tmp directory"
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd
