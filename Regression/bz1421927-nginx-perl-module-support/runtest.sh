#!/bin/bash
# vim: dict+=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /CoreOS/nginx/Regression/bz1421927-nginx-perl-module-support
#   Description: Test for BZ#1421927 (Perl module support)
#   Author: Joe Orton <jorton@redhat.com>
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Copyright (c) 2017 Red Hat, Inc.
#
#   This copyrighted material is made available to anyone wishing
#   to use, modify, copy, or redistribute it subject to the terms
#   and conditions of the GNU General Public License version 2.
#
#   This program is distributed in the hope that it will be
#   useful, but WITHOUT ANY WARRANTY; without even the implied
#   warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
#   PURPOSE. See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public
#   License along with this program; if not, write to the Free
#   Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
#   Boston, MA 02110-1301, USA.
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Include Beaker environment
. /usr/share/beakerlib/beakerlib.sh || exit 1

PACKAGES=${PACKAGES:-"nginx nginx-mod-http-perl"}

rlJournalStart
    rlPhaseStartSetup
        rlRun "rlImport nginx/nginx"
        rlRun "GLOBAL_CONF=$nginxCONFDIR/conf.d/rhts-bz1421927.conf"
        rlRun "SERVER_CONF=$nginxCONFDIR/default.d/rhts-bz1421927.conf"
        rlRun "SSIDIR=${nginxROOTDIR}/rhts-ssi"
        rlAssertRpm --all

        rlRun "echo 'perl_require rhtshello.pm;' > $GLOBAL_CONF"
        rlRun "cp perl.conf $SERVER_CONF"
        rlRun "eval `perl -V:installvendorarch`"
        rlRun "nginxPERLDIR=${installvendorarch}"
        rlRun "HELLO_PM=${nginxPERLDIR}/rhtshello.pm"
        rlRun "cp hello.pm $HELLO_PM"
        rlRun "mkdir -p $SSIDIR"
        rlRun "cp ssi.html $SSIDIR"

        rlRun "TmpDir=\$(mktemp -d)" 0 "Creating tmp directory"
        rlRun "pushd $TmpDir"
    rlPhaseEnd

    rlPhaseStartTest "Test Perl handler"
        rlRun "rlServiceStart $nginxHTTPD" 
        rlRun "curl http://localhost/rhts-bz1421927 | tee output"
        rlAssertGrep "Hello, nginx-perl-world" output
    rlPhaseEnd

    rlPhaseStartTest "Test nginx Perl SSI function call"
        rlRun "curl http://localhost/rhts-ssi/ssi.html | tee ssi.html"
        rlAssertGrep "meaning-of-life=42" ssi.html
    rlPhaseEnd

    rlPhaseStartCleanup
        rlRun "popd"
        rlServiceRestore $nginxHTTPD
        rlRun "rm -r $TmpDir" 0 "Removing tmp directory"
        rlRun "rm -f $SERVER_CONF $GLOBAL_CONF $HELLO_PM" 0 "Removing tmp files"
        rlRun "rm -f $SSIDIR/ssi.html"
        rlRun "rmdir $SSIDIR"
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd
