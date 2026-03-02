#!/bin/bash
# vim: dict+=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /CoreOS/nginx/Regression/bz1825683-Outdated-Red-Hat-branding-in-nginx-default-page
#   Description: Test for BZ#1825683 (Outdated Red Hat branding used in nginx default)
#   Author: Iveta Cesalova <icesalov@redhat.com>
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Copyright (c) 2020 Red Hat, Inc.
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

rlJournalStart
    rlPhaseStartSetup
        rlAssertRpm --all
        rlRun "rlImport nginx/nginx"
        rlRun "TmpDir=\$(mktemp -d)" 0 "Creating tmp directory"
        rlRun "pushd $TmpDir"
        # Backup and remove SSL configuration to avoid password prompt on RHEL 9.7+
        # See BZ#2170808 - SSL keys are password-protected by default
        rlRun "rlFileBackup --namespace nginx_ssl /etc/nginx/conf.d/ssl.conf" 0,1
        rlRun "rm -f /etc/nginx/conf.d/ssl.conf" 0,1
        rlRun "rlServiceStart $nginxHTTPD"
    rlPhaseEnd

    rlPhaseStartTest
        rlRun "curl http://localhost/icons/poweredby.png > my.png" 0
        rlRun "cmp my.png /usr/share/pixmaps/poweredby.png" 0 "Badges aren't different"
    rlPhaseEnd

    rlPhaseStartCleanup
        # Restore SSL configuration if it was backed up
        rlRun "rlFileRestore --namespace nginx_ssl" 0,1
        rlRun "rlServiceStop $nginxHTTPD"
        rlRun "popd"
        rlRun "rm -r $TmpDir" 0 "Removing tmp directory"
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd
