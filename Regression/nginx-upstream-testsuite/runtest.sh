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

WHITELIST=$PWD/whitelist.txt
PACKAGES=${PACKAGES:-nginx}
PEGREV=ea4142211e03c8a8fd2e734f2199b623c794eda9

rlJournalStart
    rlPhaseStartSetup
        rlAssertRpm --all
        rlAssertBinaryOrigin $PACKAGES
        rlRun "rlImport nginx/nginx" || rlDie
        # Deactivate Perl module local::lib, which is sometimes activated by
        # default and makes an unpleasant mess in search paths
        rlRun "eval $(perl -Mlocal::lib=--deactivate-all)" 0-255 \
              "Deactivating local::lib"
        if rlIsRHEL 6; then
            rlRun "cp Config.pm /usr/share/perl5/CPAN/Config.pm" 0
                  "Copying CPAN configuration file"
        else
            rlRun "yes '' | cpan -v" 0-255 "Running CPAN auto-configuration"
        fi

        rlRun "TmpDir=\$(mktemp -d)" 0 "Creating tmp directory"
        rlRun "cp Nginx.pm $TmpDir"
        rlRun "pushd $TmpDir"
        # Install Perl modules to test them with nginx
        for MOD in Net::SSLeay FCGI SCGI; do
            perl -e "use $MOD" || rlRun "cpan $MOD" 0 "Installing $MOD"
        done

        # Same for IO-Socket-SSL Perl module (we need a newer version that the
        # one currently available in repository, so it has to be installed
        # manually)
        rlLog "Build IO::Socket::SSL"
        if ! perl -e "use IO::Socket::SSL"; then
            rlRun "git clone https://github.com/noxxi/p5-io-socket-ssl.git"
            rlRun "cd $TmpDir/p5-io-socket-ssl"
            rlRun "yes | perl Makefile.PL"
            rlRun "make"
            rlRun "make install"
        fi

        # Same for uWSGI
        rlLog "Build uWSGI"
           rlRun "cd $TmpDir"
           rlRun "git clone https://github.com/unbit/uwsgi.git"
           rlRun "cd $TmpDir/uwsgi"
           if rlIsRHEL '>=8'; then rlRun "sed -i 's/python/python2/g' Makefile"; fi
           rlRun "make"
           rlRun "export PATH=$PATH:$(pwd)"

        # Download upstream test suite
        rlRun "cd $TmpDir"
        rlRun "git clone https://github.com/nginx/nginx-tests.git"
        rlRun "cd $TmpDir/nginx-tests"
        rlRun "git checkout --quiet $PEGREV"
        if rlIsRHEL '>=8'; then rlRun "sed -i 's/^default_bits = 1024/default_bits = 2048/g' *.t"; fi
        rlRun "rm -f lib/Test/Nginx.pm && cp $TmpDir/Nginx.pm $TmpDir/nginx-tests/lib/Test"
    rlPhaseEnd

    rlPhaseStartTest
        # Uncomment this to run entire test suite:
        #rlRun "TEST_NGINX_BINARY=\$(which nginx) prove ." 0 "Run whole test suite"
        # Run whitelisted tests is known to pass with 1.4.x
        MODULES="${nginxROOTPREFIX}/usr/lib64/nginx/modules"
        rlRun "TEST_NGINX_BINARY=\$(which nginx) TEST_NGINX_GROUP=\$(id -g nginx) TEST_NGINX_MODULES=$MODULES TEST_NGINX_LEAVE=1 xargs prove < ${WHITELIST} | tee test.log" 0 "Run test suite w/whitelist"

        rlBundleLogs test.log ./test.log
        # For each test, check whether it ran successfully (PASS), was skipped
        # (WARN) or failed (FAIL).
        sed -i -n '/\.\/.*\.t/p' test.log
        while read line; do
            if (echo "$line" | grep 'ok\s*$'); then
                rlPass "$line"
            elif (echo "$line" | grep 'skipped'); then
                rlLogWarning "$line"
            else
                rlFail "$line"
            fi
        done < test.log
    rlPhaseEnd

    rlPhaseStartCleanup
        rlRun "rm -r $TmpDir" 0 "Removing tmp directory"
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd
