#!/bin/bash
# vim: dict+=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /CoreOS/nginx/Sanity/reverse-proxy
#   Description: Checks the reverse proxy use case
#   Author: Martin Frodl <mfrodl@redhat.com>
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Copyright (c) 2014 Red Hat, Inc.
#
#   This program is free software: you can redistribute it and/or
#   modify it under the terms of the GNU General Public License as
#   published by the Free Software Foundation, either version 2 of
#   the License, or (at your option) any later version.
#
#   This program is distributed in the hope that it will be
#   useful, but WITHOUT ANY WARRANTY; without even the implied
#   warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
#   PURPOSE.  See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program. If not, see http://www.gnu.org/licenses/.
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Include Beaker environment
. /usr/bin/rhts-environment.sh || exit 1
. /usr/share/beakerlib/beakerlib.sh || exit 1

PACKAGE=${PACKAGE:-nginx}


rlJournalStart
    rlPhaseStartSetup
        rlRun "rlImport nginx/nginx" 0 "Import nginx library" || rlDie
        rlRun "rlImport selinux-policy/common" 0 "Import selinux library"
        rlRun "TmpDir=\$(mktemp -d)" 0 "Creating tmp directory"

        # Prepare directories and files to be tested
        rlAssertExists "$nginxROOTDIR" && {
            for DIR in default images scripts; do
                rlRun "mkdir -p $nginxROOTDIR/$DIR" 0 "Creating directory $nginxROOTDIR/$DIR"
            done
            rlRun "touch $nginxROOTDIR/default/test.html" 0 "Creating test.html"
            rlRun "touch $nginxROOTDIR/images/test.png" 0 "Creating test.png"
            rlRun "touch $nginxROOTDIR/scripts/test.js" 0 "Creating test.js"
        }

        rlRun "cp nginx.conf $nginxCONFDIR/conf.d" 0 \
              "Copying nginx.conf to conf.d"
        rlRun "pushd $TmpDir"
        rlRun "nginxVarExpand $nginxCONFDIR/conf.d/nginx.conf" 0 \
              "Expanding variables in nginx.conf"
        for PORT in 9080 9081 9082 9083; do
            rlSEPortAdd tcp $PORT http_port_t
        done
	rlSEBooleanOn httpd_can_network_connect

        ERR_LOG=$nginxLOGDIR/error.log
        rlRun "rlFileBackup $nginxLOGDIR/error.log" 0,8
        rlRun "> $ERR_LOG" 0 "Cleaning nginx error log"
    rlPhaseEnd

    rlPhaseStartTest
        rlRun "nginxStart" 0 "Starting nginx server"
	sleep 3

        # Test if the reverse proxy correctly resolves paths based on URI
        rlRun "wget http://$(hostname):9080/test.html"
        rlRun "wget http://$(hostname):9080/img/test.png"
        rlRun "wget http://$(hostname):9080/test.js"

        # A simple stress test with concurrency. Note that the IP 127.0.0.1 is
        # used instead of hostname here because of a bug in ab (BZ#1125269)
        # which causes troubles when host name is resolved to IPv6
        NUM_REQ=100000
        CONC=5

        rlRun "ab -n $NUM_REQ -c $CONC http://127.0.0.1:9080/test.html | tee first.log &"
        rlRun "ab -n $NUM_REQ -c $CONC http://127.0.0.1:9080/img/test.png | tee second.log &"
        rlRun "ab -n $NUM_REQ -c $CONC http://127.0.0.1:9080/test.js | tee third.log &"
        rlRun "wait" 0 "Waiting for ab to finish"

        for LOG in first.log second.log third.log; do
            rlAssertGrep "Complete requests:\s*$NUM_REQ" $LOG || grep "Complete requests" $LOG
        done

        if [[ -s $ERR_LOG ]]; then
            rlLogWarning "There have been error messages"
            rlLogWarning "Please check the attached log in error_log.tar.gz"
            rlBundleLogs error_log $ERR_LOG
        fi

        rlRun "nginxStop" 0 "Stopping nginx server"
    rlPhaseEnd

    rlPhaseStartCleanup
        rlRun "rlFileRestore" 0,8,16
        rlSEPortRestore
	rlSEBooleanRestore httpd_can_network_connect
        rlAssertExists "$nginxROOTDIR" && {
            for DIR in default images scripts; do
                rlRun "rm -r $nginxROOTDIR/$DIR/" 0 \
                    "Removing $nginxROOTDIR/$DIR/"
            done
        }
        rlRun "rm -f $nginxCONFDIR/conf.d/nginx.conf"
        rlRun "popd"
        rlRun "rm -r $TmpDir" 0 "Removing tmp directory"
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd
