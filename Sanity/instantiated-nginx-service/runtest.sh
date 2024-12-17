#!/bin/bash
# vim: dict+=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /CoreOS/nginx/Sanity/instantiated-nginx-service
#   Description: Test for instantiated httpd.service
#   Author: Joe Orton <jorton@redhat.com>
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Copyright (c) 2024 Red Hat, Inc.
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

PACKAGES="${PACKAGES:-nginx}"

rlJournalStart
    rlPhaseStartSetup
        rlRun "rlImport --all" 0 "Import beaker libraries"
        rlAssertRpm --all
        rlRun "CONF=$nginxCONFDIR"
        rlRun "ROOTDIR=/srv/www"
        rlRun "rm -rf $ROOTDIR && mkdir -p /srv/www"
        if selinuxenabled ; then
            rlRun "chcon -t public_content_t /srv/www"
        fi
        rlRun "mkdir -p ${ROOTDIR}/beaker-{1,2,3}"
        rlRun "echo beaker-the-first > ${ROOTDIR}/beaker-1/index.html"
        rlRun "echo beaker-the-second > ${ROOTDIR}/beaker-2/index.html"

        rlRun "rm -f ${nginxLOGDIR}/*_log"
        rlRun "rlServiceStop nginx"
        rlRun "TmpDir=\$(mktemp -d)" 0 "Creating tmp directory"
        rlRun "pushd $TmpDir"

        # Set up instance config files for services nginx@beaker-1 and httpd@beaker-2
        if test -d $httpROOTPREFIX/usr/share/doc/nginx-core; then
            rlRun "INSTCONF=$httpROOTPREFIX/usr/share/doc/${httpHTTPD}-core/instance.conf"
        else
            rlRun "INSTCONF=$httpROOTPREFIX/usr/share/doc/$httpHTTPD/instance.conf"
        fi
        rlAssertExists "$INSTCONF"
        rlRun "sed '/^ *listen/s/80/81/;/^ *root/s,/usr.*,/srv/beaker-1,' < $INSTCONF > ${CONF}/beaker-1.conf"
        rlRun "sed '/^Listen/s/80/82/;/^DocumentRoot/s,html,html/beaker-2,' < $INSTCONF > ${CONF}/beaker-2.conf"

        if selinuxenabled; then
            rlRun "rlSEPortAdd tcp 81 http_port_t"
            rlRun "rlSEPortAdd tcp 82 http_port_t"
        fi

        # Log running processes to help diagnose port conflicts
        rlRun -l "ss -pant"
    rlPhaseEnd

    rlPhaseStartTest "Startup and service checks"
        rlRun "rlServiceStart nginx@beaker-1"
        # First service => active once started
        rlRun "systemctl is-active -q nginx@beaker-1" 0
        # Second service => inactive until started

        rlRun "systemctl is-active -q nginx@beaker-2" 3
        rlRun "rlServiceStart nginx@beaker-2"
        # Second service => now active as well
        rlRun "systemctl is-active -q nginx@beaker-2" 0
        rlRun "sleep 2"

        # Ensure mod_systemd reported status correctly
        rlRun "systemctl status nginx@beaker-1 > status.1"
        rlRun "systemctl status nginx@beaker-2 > status.2"
        rlAssertGrep 'the configuration file /etc/nginx/beaker-1.conf syntax is ok' status.1
        rlAssertGrep 'the configuration file /etc/nginx/beaker-2.conf syntax is ok' status.2

        rlRun "sleep 1"
        # Check only the instance-specific error logs are there
        rlAssertNotExists "$httpLOGDIR/error_log"
        rlAssertNotExists "$httpLOGDIR/access_log"
        rlAssertExists "$httpLOGDIR/beaker-1_error_log"
        rlAssertExists "$httpLOGDIR/beaker-2_error_log"
        rlAssertGrep 'start worker processes' "$httpLOGDIR/beaker-1_error_log"
        rlAssertGrep 'start worker processes' "$httpLOGDIR/beaker-2_error_log"
    rlPhaseEnd

    rlPhaseStartTest "Requests and access_logs"
        # Test the docroot config is right, and the right access_log is used
        rlRun "curl http://localhost:81/?beaker-test-1 > output.1"
        rlRun "curl http://localhost:82/?beaker-test-2 > output.2"
        rlAssertGrep beaker-the-first output.1
        rlAssertGrep beaker-the-second output.2

        # Check the access logging works
        rlRun "sleep 1"
        rlAssertExists "$httpLOGDIR/beaker-1_access_log"
        rlAssertExists "$httpLOGDIR/beaker-2_access_log"
        rlAssertGrep 'GET /?beaker-test-1' "$httpLOGDIR/beaker-1_access_log"
        rlAssertGrep 'GET /?beaker-test-2' "$httpLOGDIR/beaker-2_access_log"
    rlPhaseEnd

    rlPhaseStartTest "Service reload tests"
        # Now adjust the config for both services and reload, ensure
        # ONLY one running service actually reloads the new config.
        rlRun "sed '/^DocumentRoot/s,html/beaker-1,html/beaker-3,' -i ${CONF}/beaker-1.conf"
        rlRun "sed '/^DocumentRoot/s,html/beaker-2,html,' -i ${CONF}/beaker-2.conf"
        rlRun "systemctl reload nginx@beaker-1"

        rlRun "curl http://localhost:81/ > output.3"
        rlRun "curl http://localhost:82/ > output.4"

        rlAssertGrep beaker-the-third output.3
        rlAssertGrep beaker-the-second output.4

        rlRun "rlServiceStop nginx@beaker-1"
        rlRun "rlServiceStop nginx@beaker-2"
    rlPhaseEnd

    rlPhaseStartCleanup
        rlRun "popd"
        if selinuxenabled; then
            rlSEPortRestore
        fi
        rlRun "rm -r $TmpDir" 0 "Removing tmp directory"
        rlRun "rm -f ${CONF}/beaker-{1,2}.conf"
        rlRun "rm -f ${httpLOGDIR}/beaker-*_log"
        rlRun "rm -rf ${ROOTDIR}"
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd
