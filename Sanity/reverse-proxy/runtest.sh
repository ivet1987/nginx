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
        rlRun "rlImport nginx/nginx" 0 "Import nginx library"
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
    rlPhaseEnd

    rlPhaseStartTest
        rlRun "nginxStart" 0 "Starting nginx server"
        rlRun "wget http://$(hostname):8080/test.html"
        rlRun "wget http://$(hostname):8080/img/test.png"
        rlRun "wget http://$(hostname):8080/test.js"
        rlRun "nginxStop" 0 "Stopping nginx server"
    rlPhaseEnd

    rlPhaseStartCleanup
        rlAssertExists "$nginxROOTDIR" && {
            for DIR in default images scripts; do
                rlRun "rm -r $nginxROOTDIR/$DIR/" 0 \
                    "Removing $nginxROOTDIR/$DIR/"
            done
        }
        rlRun "popd"
        rlRun "rm -r $TmpDir" 0 "Removing tmp directory"
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd
