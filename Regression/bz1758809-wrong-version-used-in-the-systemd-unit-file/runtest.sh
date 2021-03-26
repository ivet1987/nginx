#!/bin/bash
# vim: dict+=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /CoreOS/nginx/Regression/bz1758809-wrong-version-used-in-the-systemd-unit-file
#   Description: Test for BZ#1758809 (Nginx service does not start (wrong version used)
#   Author: Maryna Nalbandian <mnalband@redhat.com>
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Copyright (c) 2019 Red Hat, Inc.
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
. /usr/share/beakerlib/beakerlib.sh || exit 1

PACKAGES=${PACKAGES:-nginx}
rlJournalStart
    rlPhaseStartSetup
        rlAssertRpm --all
        rlRun "rlImport nginx/nginx" 0 "Import nginx library" || rlDie
        rlRun "TmpDir=\$(mktemp -d)" 0 "Creating tmp directory"
        rlRun "pushd $TmpDir"
        rlAssertBinaryOrigin nginx
        rlRun "nginxSecureStart"
    rlPhaseEnd

    rlPhaseStartTest
        unit_file=/usr/lib/systemd/system/$nginxCOLLECTION_NAME-nginx.service
        rlLog "Checking Service File"
        rlAssertGrep $nginxCOLLECTION_NAME $unit_file 
        rlLog "Checking 404.html File"
        rlRun -s "curl http://localhost/dummy.html"
        rlAssertGrep $nginxCOLLECTION_NAME $rlRun_LOG
        rlLog "Checking Test Page (index.html)"
        rlRun -s "curl http://127.0.0.1" 
        rlAssertGrep $nginxCOLLECTION_NAME $rlRun_LOG
        rlLog "Checking the Page is Temporarily Unavailable 50x"
        rlAssertGrep $nginxCOLLECTION_NAME ${nginxROOTDIR}/50x.html 
    rlPhaseEnd

    rlPhaseStartCleanup
        rlRun "nginxSecureStop"
        rlRun "popd"
        rlRun "rm -r $TmpDir" 0 "Removing tmp directory"
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd

