#!/bin/bash
# vim: dict+=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /CoreOS/nginx/Regression/bz2086527-No-logrotating-nginx-logs-from-appstream
#   Description: Test for BZ#2086527 (No logrotating nginx logs from @appstream)
#   Author: Iveta Cesalova <icesalov@redhat.com>
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Copyright (c) 2022 Red Hat, Inc.
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

PACKAGES=${PACKAGES:-"nginx"}

rlJournalStart
    rlPhaseStartSetup
        rlAssertRpm --all
        rlRun "rlImport nginx/nginx"
        rlRun "TmpDir=\$(mktemp -d)" 0 "Creating tmp directory"
        rlRun "pushd $TmpDir"
        rlRun "rlServiceStart $nginxHTTPD"
        rlRun "sed -i 's/error_log \/var\/log\/nginx\/error.log;/error_log \/var\/log\/nginx\/error.log debug;/g' $nginxCONFDIR/nginx.conf"
    rlPhaseEnd

    rlPhaseStartTest
        rlRun "curl localhost > /dev/null 2>&1"
        rlRun "cat /var/log/nginx/access.log | tee output"
        rlRun "logrotate -vf /etc/logrotate.d/nginx"
        rlRun "cat /var/log/nginx/access.log.1"
        rlRun "curl localhost > /dev/null 2>&1"
        OLD=$(cat $TmpDir/output | wc -l)
        NEW=$(cat \/var\/log\/nginx\/access.log | wc -l)
        rlAssertEquals "Logging is working" $NEW $OLD
    rlPhaseEnd

    rlPhaseStartCleanup
        rlRun "rlServiceStop $nginxHTTPD"
        rlRun "popd"
        rlRun "rm -r $TmpDir" 0 "Removing tmp directory"
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd

