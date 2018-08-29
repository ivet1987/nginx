#!/bin/bash
# vim: dict=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /CoreOS/nginx/Sanity/php-fpm-integration
#   Description: Sanity test for nginx with php-fpm
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

if echo $COLLECTIONS | grep php70; then
    FPM="rh-php70-php-fpm"
elif echo $COLLECTIONS | grep php56; then
    FPM="rh-php56-php-fpm"
elif echo $COLLECTIONS | grep php55; then
    FPM="php55-php-fpm"
elif echo $COLLECTIONS | grep php54; then
    FPM="php54-php-fpm"
else
    FPM="php-fpm"
fi

URL=http://127.0.0.1:81/
RPURL=http://127.0.0.1:81/rp/
PHPURL=http://127.0.0.1:81/info.php

PACKAGES=${PACKAGES:-"nginx $FPM"}

rlJournalStart
    rlPhaseStartSetup
        rlRun "rlImport nginx/nginx"
        rlAssertRpm --all
        rlAssertBinaryOrigin nginx
        rlAssertExists ${nginxCONFDIR}
        rlAssertExists ${nginxLOGDIR}
        DOCROOT=$nginxROOTDIR/rhts-nginx-root
        MYCONF=${nginxCONFDIR}/conf.d/rhts-nginx-sanity.conf

        rlRun "mkdir ${DOCROOT}"
        rlRun "echo '<?php echo phpinfo();' > ${DOCROOT}/info.php"

	if rlIsRHEL 8;then
            rlRun "cp nginx-rhel8.conf ${MYCONF}"

        else
            rlRun "cp nginx.conf ${MYCONF}"
        fi
        rlRun "sed -i 's|ROOTDIR|$nginxROOTDIR|' ${MYCONF}"

        rlRun "TmpDir=\$(mktemp -d)" 0 "Creating tmp directory"
        rlRun "pushd $TmpDir"

    rlPhaseEnd

    rlPhaseStartTest
        rlRun "rlServiceStart $nginxHTTPD" 
        rlRun "rlServiceStart $FPM"
        rlRun "sleep 2"

        rlRun "curl $PHPURL > php.html"
        rlAssertGrep 'PHP Version' php.html
        if echo $COLLECTIONS | grep php; then
            rlRun "PHPSCL=\$(echo $FPM | sed s,-php-fpm,,)"
            rlRun "PHPRAWVER=\$(scl enable $PHPSCL 'php-fpm -v' | head -1)"
        else
            rlRun "PHPRAWVER=\$(php-fpm -v | head -1)"
        fi
        rlRun "PHPVER=\$(echo \"$PHPRAWVER\" | awk '{print \$2}')" \
                  0 "parsing PHP version from php command"
        rlRun "PHPVER2=\$(grep -o 'PHP Version [0-9]*\.[0-9]*\.[0-9]*' php.html | awk '{print \$3}')"\
            0 "getting PHP version from downloaded page"
        rlRun " [ $PHPVER = $PHPVER2 ] " 0 "checking PHP version"
        rlLog "PHP version from php command: $PHPVER"
        rlLog "PHP version from downloaded page: $PHPVER2"

        rlRun "ab -c 20 -n 10000 $PHPURL"

        rlAssertGrep "/info.php" "$nginxLOGDIR/access.log"

        rlRun "rlServiceStop $nginxHTTPD"
        rlRun "rlServiceStop $FPM"
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
