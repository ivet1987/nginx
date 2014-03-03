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
. /usr/bin/rhts-environment.sh || exit 1
. /usr/share/beakerlib/beakerlib.sh || exit 1

CONFDIR=/etc/nginx/conf.d
DOCROOT=/var/www/rhts-nginx-root
LOGROOT=/var/log/nginx14

if echo $COLLECTIONS | grep nginx14; then
    NGINX="nginx14-nginx"
    CONFDIR=/opt/rh/nginx14/root/${CONFDIR}
else
    NGINX="nginx"
fi

URL=http://127.0.0.1:81/
RPURL=http://127.0.0.1:81/rp/
PHPURL=http://127.0.0.1:81/info.php

PACKAGES=${PACKAGES:-"$NGINX"}
MYCONF=${CONFDIR}/rhts-nginx-sanity.conf

rlJournalStart
    rlPhaseStartSetup
        rlAssertRpm --all
        rlAssertBinaryOrigin nginx
        rlAssertExists ${CONFDIR}
        rlAssertExists ${LOGROOT}

        rlRun "mkdir ${DOCROOT} ${PHPROOT}"
        rlRun "echo this is the index > ${DOCROOT}/index.html"
        rlRun "echo '<?php echo phpinfo();' > ${DOCROOT}/info.php"

        rlRun "cp nginx.conf ${MYCONF}"

        rlRun "TmpDir=\$(mktemp -d)" 0 "Creating tmp directory"
        rlRun "pushd $TmpDir"

    rlPhaseEnd

    rlPhaseStartTest
        rlRun "rlServiceStart $NGINX" 
        rlRun "sleep 2"

        rlRun "curl $URL > output.html"
        rlAssertNotDiffer output.html $DOCROOT/index.html
        rlRun "curl $URL/rp/ > output2.html"
        rlAssertNotDiffer output2.html $DOCROOT/index.html

        rlAssertExists "$LOGROOT/access.log"
        rlAssertExists "$LOGROOT/error.log"

        rlRun "ab -c 100 -n 10000 $URL"
        rlRun "ab -c 100 -n 10000 $RPURL"

        rlRun "rlServiceStop $NGINX"
        rlRun "sleep 2"

    rlPhaseEnd

    rlPhaseStartCleanup
        rlRun "popd"
        rlRun "rm -r $TmpDir" 0 "Removing tmp directory"
        rlRun "rm -rf ${DOCROOT}"
        rlRun "rm -f ${MYCONF}"
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd
