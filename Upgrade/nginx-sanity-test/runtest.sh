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

distribution_mcase__setup() {
        rlAssertRpm --all
        rlRun "rlImport nginx/nginx"
        MYCONF=${nginxCONFDIR}/conf.d/rhts-nginx-sanity.conf
        DOCROOT=$nginxROOTDIR/rhts-nginx-root
        #rlAssertBinaryOrigin nginx
        rlAssertExists ${nginxCONFDIR}
        rlAssertExists ${nginxLOGDIR}

        rlRun "mkdir -p ${DOCROOT}"
        rlRun "echo this is the index > ${DOCROOT}/index.html"
        rlRun "echo '<?php echo phpinfo();' > ${DOCROOT}/info.php"

        rlRun "cp nginx.conf ${MYCONF}"
        rlRun "sed -i 's|ROOTDIR|$nginxROOTDIR|' ${MYCONF}"

        rlRun "TmpDir=\$(mktemp -d)" 0 "Creating tmp directory"
        rlRun "pushd $TmpDir"
        rlRun "sleep 2" 0 "Waiting on nginx to start"
}

distribution_mcase__test() {
        setsebool -P httpd_can_network_connect on
        rlRun "systemctl enable --now nginx"
        rlRun "curl $URL > output.html"
        rlAssertNotDiffer output.html /usr/share/nginx/html/rhts-nginx-root/index.html
        rlRun "curl $URL/rp/ > output2.html"
        rlAssertNotDiffer output2.html /usr/share/nginx/html/rhts-nginx-root/index.html

        rlAssertExists "/var/log/nginx/access.log"
        rlAssertExists "/var/log/nginx/error.log"

        rlRun "ab -c 10 -n 10000 $URL"
        rlRun "ab -c 10 -n 10000 $RPURL"
        rlRun "systemctl stop nginx"
}
distribution_mcase__cleanup() {
        rlRun "popd"
        setsebool -P httpd_can_network_connect off
        rlRun "rm -r $TmpDir" 0 "Removing tmp directory"
        rlRun "rm -rf usr/share/nginx/html/rhts-nginx-root"
        rlRun "rm -f /etc/nginx/conf.d/rhts-nginx-sanity.conf"
}

rlJournalStart
    rlPhaseStartSetup
        rlPhaseStartSetup "init"
        rlImport "ControlFlow/mcase"
    rlPhaseEnd
    distribution_mcase__run

rlJournalPrintText
rlJournalEnd
