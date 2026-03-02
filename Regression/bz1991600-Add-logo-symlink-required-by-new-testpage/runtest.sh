#!/bin/bash
# vim: dict+=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /CoreOS/nginx/Regression/bz1991600-Add-logo-symlink-required-by-new-testpage
#   Description: Test for BZ#1991600 (Add logo symlink required by new testpage)
#   Author: Iveta Cesalova <icesalov@redhat.com>
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Copyright (c) 2021 Red Hat, Inc.
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

PACKAGES=${PACKAGES:-"nginx"}
SPEC="/root/rpmbuild/SPECS/nginx.spec"

rlJournalStart
    rlPhaseStartSetup
        rlAssertRpm --all
        rlRun "rlImport nginx/nginx"
        rlRun "TmpDir=\$(mktemp -d)" 0 "Creating tmp directory"
        rlRun "pushd $TmpDir"
        rlRun "rlFetchSrcForInstalled $PACKAGES"
        # Backup and remove SSL configuration to avoid password prompt on RHEL 9.7+
        # See BZ#2170808 - SSL keys are password-protected by default
        rlRun "rlFileBackup --namespace nginx_ssl /etc/nginx/conf.d/ssl.conf" 0,1
        rlRun "rm -f /etc/nginx/conf.d/ssl.conf" 0,1
        rlRun "rlServiceStart $nginxHTTPD"
    rlPhaseEnd

    rlPhaseStartTest
        rlRun "rpm -ivh ${PACKAGE}*.src.rpm"
        rlRun "cat $SPEC | grep /nginx/html/system_noindex_logo.png"
        rlRun "curl http://localhost/ > output"
        rlAssertNotDiffer /usr/share/nginx/html/index.html output
    rlPhaseEnd

    rlPhaseStartCleanup
        # Restore SSL configuration if it was backed up
        rlRun "rlFileRestore --namespace nginx_ssl" 0,1
        rlRun "rlServiceStop $nginxHTTPD"
        rlRun "popd"
        rlRun "rm -r $TmpDir" 0 "Removing tmp directory"
    rlPhaseEnd
rlJournalEnd
