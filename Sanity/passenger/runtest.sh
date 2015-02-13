#!/bin/bash
# vim: dict+=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /CoreOS/nginx16/Sanity/passenger
#   Description: Sanity test for passenger module
#   Author: Martin Frodl <mfrodl@redhat.com>
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Copyright (c) 2015 Red Hat, Inc.
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
        rlRun "rlImport nginx/nginx" 0 "Importing nginx library" || rlDie
        rlAssertRpm --all

        rlFileBackup --clean $nginxCONFDIR/conf.d/
        rlRun "cp passenger.conf $nginxCONFDIR/conf.d/" 0 \
            "Configuring nginx with passenger support"
        rlRun "nginxVarExpand $nginxCONFDIR/conf.d/passenger.conf"
        rlRun "nginxStop" 0 "Ensuring nginx is not running"

        rlFileBackup /etc/hosts
        rlRun "echo '127.0.0.1   www.app4000.com www.app4001.com www.app4002.com' \
            >> /etc/hosts" 0 "Configuring hosts file"

        TESTDIR=$nginxROOTPREFIX/usr/share/nginx
        rlFileBackup --clean $TESTDIR
        for PORT in {4000..4002}; do
            rlRun "mkdir -p $TESTDIR/app$PORT/public"
            rlRun "mkdir -p $TESTDIR/app$PORT/tmp"
            rlRun "cp passenger_wsgi.py $TESTDIR/app$PORT"
            rlRun "pushd $TESTDIR/app$PORT"
            rlRun "sed -i 's/%%PORT%%/$PORT/' passenger_wsgi.py"
            rlRun "passenger start --daemonize --port $PORT"
            rlRun "popd"
        done
        rlRun "nginx"
    rlPhaseEnd

    rlPhaseStartTest
        for PORT in {4000..4002}; do
            rlRun -s "curl http://www.app${PORT}.com"
            rlAssertGrep "port $PORT" $rlRun_LOG
        done
    rlPhaseEnd

    rlPhaseStartCleanup
        rlRun "nginx -s stop"
        for PORT in {4000..4002}; do
            rlRun "pushd $TESTDIR/app$PORT"
            rlRun "passenger stop --port $PORT"
            rlRun "popd"
        done
        rlFileRestore
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd
