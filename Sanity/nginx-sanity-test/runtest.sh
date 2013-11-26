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

PACKAGE="nginx"
SERVICE="nginx"
CONFDIR=/etc/nginx/conf.d
DOCROOT=/var/www/rhts-nginx-root
URL=http://127.0.0.1:81/
RPURL=http://127.0.0.1:81/rp/

LOGROOT=/var/log/nginx

PHPURL=http://127.0.0.1:81/info.php
FPMSVC=php-fpm
FPMPKG=php-fpm

if test -d /opt/rh/php54; then
    FPMSVC=php54-php-fpm
    FPMPKG=php54-php-fpm
fi
if test -d /opt/rh/php55; then
    FPMSVC=php55-php-fpm
    FPMPKG=php55-php-fpm
fi
if test -d /opt/rh/nginx14; then
    SERVICE=nginx14-nginx
    PACKAGE=nginx14-nginx
    CONFDIR=/opt/rh/nginx14/root/etc/nginx/conf.d
fi

MYCONF=${CONFDIR}/rhts-nginx-sanity.conf

rlJournalStart
    rlPhaseStartSetup
        rlAssertRpm $PACKAGE
        rlAssertRpm $FPMPKG

        rlRun "mkdir ${DOCROOT} ${PHPROOT}"
        rlRun "echo this is the index > ${DOCROOT}/index.html"
        rlRun "echo '<?php echo phpinfo();' > ${DOCROOT}/info.php"

        rlRun "cp nginx.conf ${MYCONF}"

        rlRun "TmpDir=\$(mktemp -d)" 0 "Creating tmp directory"
        rlRun "pushd $TmpDir"

    rlPhaseEnd

    rlPhaseStartTest
        rlRun "rlServiceStart $SERVICE" 
        rlRun "sleep 2"

        rlRun "curl $URL > output.html"
        rlAssertNotDiffer output.html $DOCROOT/index.html
        rlRun "curl $URL/rp/ > output2.html"
        rlAssertNotDiffer output2.html $DOCROOT/index.html

        rlAssertExists "$LOGROOT/access.log"
        rlAssertExists "$LOGROOT/error.log"

        rlRun "ab -c 100 -n 10000 $URL"
        rlRun "ab -c 100 -n 10000 $RPURL"

        rlRun "rlServiceStart $FPMSVC"

        rlRun "curl $PHPURL > php.html"
        rlAssertGrep 'PHP Version' php.html
        rlRun "ab -c 20 -n 10000 $PHPURL"

        rlAssertGrep "/info.php" "$LOGROOT/access.log"

#        rlRun "sleep 1h"
        rlRun "rlServiceStop $SERVICE"
        rlRun "rlServiceStop $FPMSVC"
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
