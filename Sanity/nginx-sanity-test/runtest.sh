#!/bin/bash
# vim: dict=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /CoreOS/nginx/Sanity/nginx-sanity-test
#   Description: Sanity test for nginx
#   Author: Joe Orton <jorton@redhat.com>
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Copyright (c) 2013 Red Hat, Inc. All rights reserved.
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


URL=http://127.0.0.1:81/
RPURL=http://127.0.0.1:81/rp/
PHPURL=http://127.0.0.1:81/info.php

PACKAGES=${PACKAGES:-"nginx"}

rlJournalStart
    rlPhaseStartSetup
        rlAssertRpm --all
        rlRun "rlImport nginx/nginx"
        rlRun "rlImport selinux-policy/common"
        MYCONF=${nginxCONFDIR}/conf.d/rhts-nginx-sanity.conf
        DOCROOT=$nginxROOTDIR/rhts-nginx-root
        rlAssertExists ${nginxCONFDIR}
        rlAssertExists ${nginxLOGDIR}

        rlSEBooleanOn httpd_can_network_connect

        rlRun "mkdir ${DOCROOT}"
        rlRun "echo this is the index > ${DOCROOT}/index.html"
        rlRun "echo '<?php echo phpinfo();' > ${DOCROOT}/info.php"

        rlRun "cp nginx.conf ${MYCONF}"
        rlRun "sed -i 's|ROOTDIR|$nginxROOTDIR|' ${MYCONF}"

        rlRun "TmpDir=\$(mktemp -d)" 0 "Creating tmp directory"
        rlRun "pushd $TmpDir"
        # Backup and remove SSL configuration to avoid password prompt on RHEL 9.7+
        # See BZ#2170808 - SSL keys are password-protected by default
        rlRun "rlFileBackup --namespace nginx_ssl /etc/nginx/conf.d/ssl.conf" 0,1
        rlRun "rm -f /etc/nginx/conf.d/ssl.conf" 0,1
        rlRun "rlServiceStart $nginxHTTPD"
        rlRun "sleep 2" 0 "Wainting on nginx to start"
    rlPhaseEnd

    rlPhaseStartTest
        rlRun "curl $URL > output.html"
        rlAssertNotDiffer output.html $DOCROOT/index.html
        rlRun "curl $URL/rp/ > output2.html"
        rlAssertNotDiffer output2.html $DOCROOT/index.html

        rlAssertExists "$nginxLOGDIR/access.log"
        rlAssertExists "$nginxLOGDIR/error.log"

        rlRun "ab -c 10 -n 10000 $URL"
        rlRun "ab -c 10 -n 10000 $RPURL"

        rlRun "rlServiceStop $nginxHTTPD"
        rlRun "sleep 2"

    rlPhaseEnd

    rlPhaseStartCleanup
        # Restore SSL configuration if it was backed up
        rlRun "rlFileRestore --namespace nginx_ssl" 0,1
        rlRun "popd"
        rlSEBooleanRestore httpd_can_network_connect
        rlRun "rm -r $TmpDir" 0 "Removing tmp directory"
        rlRun "rm -rf ${DOCROOT}"
        rlRun "rm -f ${MYCONF}"
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd
