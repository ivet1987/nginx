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

SCGIVERSION=0.6
SCGISTUB=SCGI-${SCGIVERSION}
SCGITARBALL=${SCGISTUB}.tar.gz
SCGIURL=${LOOKASIDE}/${SCGITARBALL}

UWSGIVERSION=2.0.6
UWSGISTUB=uwsgi-${UWSGIVERSION}
UWSGITARBALL=${UWSGISTUB}.tar.gz
UWSGIURL=${LOOKASIDE}/${UWSGITARBALL}

WHITELIST=$PWD/whitelist.txt

PACKAGES=${PACKAGES:-nginx14-nginx}

rlJournalStart
    rlPhaseStartSetup
        rlAssertRpm --all
        rlAssertBinaryOrigin nginx
        rlRun "TmpDir=\$(mktemp -d)" 0 "Creating tmp directory"
        rlRun "pushd $TmpDir"

        for MODULE in Module::Build FCGI SCGI; do
            perl -e "use $MOD" ||
            rlRun "yes | perl -MCPAN -e 'install $MOD'" 0 "Installing $MOD"
        done

        # Manual installation in case the automated way above should fail
        #
        # install SCGI to test if it works with nginx
        #perl -e 'use Module::Build;' || 
        #rlRun "yes | perl -MCPAN -e 'install Module::Build'" 0 \
        #    "Installing Module::Build"

        #perl -e 'use SCGI;' || {
        #    rlRun "wget $SCGIURL" 0 "Downloading SCGI package"
        #    rlRun "tar -xvf $SCGITARBALL" 0 "Extracting archive"
        #    rlRun "pushd $SCGISTUB"
        #    rlRun "perl Build.PL"
        #    rlRun "./Build"
        #    rlRun "./Build test"
        #    rlRun "./Build install"
        #    rlRun "popd"
        #}

        # same for uWSGI
        rlRun "wget $UWSGIURL" 0 "Downloading uWSGI package"
        rlRun "tar -xvf $UWSGITARBALL" 0 "Extracting archive"
        rlRun "pushd uwsgi-2.0.6"
        # I am not sure if this is necessary; feel free to remove this
        # commented section if the test does not make any trouble; uncomment
        # otherwise:
        #rlRun "yum groupinstall \"Development Tools\"" 0 \
        #    "Installing Development Tools"
        rlRun "make"
        rlRun "export PATH=$PATH:$(pwd)"
        rlRun "popd"

        # download upstream test suite
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
