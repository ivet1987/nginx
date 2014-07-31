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

LOOKASIDE=${LOOKASIDE:-http://download.eng.bos.redhat.com/qa/rhts/lookaside/}

TARVERSION=fb366c51eac6
TARSTUB=nginx-tests-${TARVERSION}
TARBALL=${TARSTUB}.tar.gz
TARURL=${LOOKASIDE}/${TARBALL}

UWSGIVERSION=2.0.6
UWSGISTUB=uwsgi-${UWSGIVERSION}
UWSGITARBALL=${UWSGISTUB}.tar.gz
UWSGIURL=${LOOKASIDE}/${UWSGITARBALL}

SSLVERSION=1.997
SSLSTUB=IO-Socket-SSL-${SSLVERSION}
SSLTARBALL=${SSLSTUB}.tar.gz
SSLURL=${LOOKASIDE}/${SSLTARBALL}

WHITELIST=$PWD/whitelist.txt

PACKAGES=${PACKAGES:-nginx14-nginx}

rlJournalStart
    rlPhaseStartSetup
        rlAssertRpm --all
        rlAssertBinaryOrigin nginx
        rlRun "TmpDir=\$(mktemp -d)" 0 "Creating tmp directory"
        rlRun "pushd $TmpDir"

        # Install Perl modules to test them with nginx
        for MOD in Module::Build FCGI SCGI; do
            perl -e "use $MOD" ||
            rlRun "yes | perl -MCPAN -e 'install $MOD'" 0 "Installing $MOD"
        done

        # Same for IO-Socket-SSL Perl module (we need a newer version that the
        # one currently available in repository, so it has to be installed
        # manually)
        rlRun "wget $SSLURL" 0 "Downloading IO-Socket-SSL module"
        rlRun "tar -xvf $SSLTARBALL" 0 "Extracting archive"
        rlRun "pushd $SSLSTUB"
        rlRun "yes | perl Makefile.PL"
        rlRun "make"
        rlRun "make install"
        rlRun "popd"

        # Same for uWSGI
        rlRun "wget $UWSGIURL" 0 "Downloading uWSGI package"
        rlRun "tar -xvf $UWSGITARBALL" 0 "Extracting archive"
        rlRun "pushd $UWSGISTUB"
        rlRun "make"
        rlRun "export PATH=$PATH:$(pwd)"
        rlRun "popd"

        # Download upstream test suite
        rlRun "wget $TARURL"
        rlRun "tar -xzvf ${TARBALL}"
        rlRun "pushd ${TARSTUB}"
    rlPhaseEnd

    rlPhaseStartTest
        # Uncomment this to run entire test suite:
        #rlRun "TEST_NGINX_BINARY=\$(which nginx) prove ." 0 "Run whole test suite"
    
        # Run whitelisted tests is known to pass with 1.4.x
        rlRun "TEST_NGINX_BINARY=\$(which nginx) xargs prove < ${WHITELIST} | tee test.log" 0 "Run test suite w/whitelist"

        # Make sure that all the tests actually passed and were not merely
        # skipped
        sed -i -n '/\.\/.*\.t/p' test.log
        while read line; do
            rlRun "echo $line | grep 'ok\s*$'" 0 "$line"
        done < test.log
    rlPhaseEnd

    rlPhaseStartCleanup
        rlRun "popd"
        rlRun "popd"
        rlRun "rm -r $TmpDir" 0 "Removing tmp directory"
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd
