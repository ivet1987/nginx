#!/bin/bash
# vim: dict+=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /CoreOS/nginx/Regression/bz1991720-ability-to-build-external-modules
#   Description: Test for BZ#1991720 (RFE Please add the ability to build external nginx)
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
LOOKASIDE=${LOOKASIDE:-http://download.eng.bos.redhat.com/qa/rhts/lookaside/}
nginx_module_vts=nginx-vts-mod.tar.gz

rlJournalStart
    rlPhaseStartSetup
        rlAssertRpm --all
        rlRun "rlImport nginx/nginx"

        MYCONF=${nginxCONFDIR}/conf.d/rhts-nginx-mod-vts.conf
        rlRun "cp nginx.conf ${MYCONF}"

        rlRun "TmpDir=\$(mktemp -d)" 0 "Creating tmp directory"
        rlRun "pushd $TmpDir"

        rlRun "wget $LOOKASIDE/$nginx_module_vts"

        rlRun "tar xzf $nginx_module_vts"
        rlRun "mkdir -p /root/rpmbuild/SOURCES/"
        rlRun "cp nginx-module-vts-*.tar.gz /root/rpmbuild/SOURCES/"
    rlPhaseEnd

    rlPhaseStartTest
        rlRun "rpmbuild -ba *.spec"
        rlRun "cp /root/rpmbuild/RPMS/*/*.rpm ./"
        rlRun "rpm -i *.rpm"
        rlRun "rlServiceStart $nginxHTTPD"
        rlRun "curl -v http://127.0.0.1/status > /dev/null 2> curl.out"
        rlRun "cat curl.out"
        rlAssertGrep "200 OK" curl.out
    rlPhaseEnd

    rlPhaseStartCleanup
        rlRun "popd"
        rlRun "rlServiceStop $nginxHTTPD"
        rlRun "rpm -e nginx-mod-vts nginx-mod-vts-debugsource nginx-mod-vts-debuginfo" 0 "Remove installed nginx-mod-vts* RPMs"
        rlRun "rm -rf /root/rpmbuild/" 0 "Removing rpmbuild dir structure"
        rlRun "rm -f ${MYCONF}"
        rlRun "rm -r $TmpDir" 0 "Removing tmp directory"
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd
