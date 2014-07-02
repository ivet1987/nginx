#!/bin/bash
# vim: dict=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /CoreOS/nginx/Sanity/daemon-selinux-context
#   Description: test selinux context of all nginx's processes
#   Author: Ondrej Ptak <optak@redhat.com>
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Copyright (c) 2014 Red Hat, Inc.
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

PACKAGES=${PACKAGES:-nginx}
rlJournalStart
    rlPhaseStartSetup
        rlAssertRpm --all
        rlRun "rlImport nginx/nginx"
        rlRun "TmpDir=\$(mktemp -d)" 0 "Creating tmp directory"
        rlRun "pushd $TmpDir"
        rlRun "rlServiceStart $nginxHTTPD"
    rlPhaseEnd

    rlPhaseStartTest
    rlRun "nginx_pids=\$(ps axo pid,comm|grep '\bnginx\b'|awk '{print \$1}')"\
            0 "detecting nginx's processes"
    rlRun " [ -n \"$nginx_pids\" ] " 0 "nginx has at least one running process"
    for p in $nginx_pids;
        do
            rlRun "ps -Z $p > ps_log" 0 "getting selinux context of process $p"
            rlAssertGrep "(system_u|unconfined_u):system_r:httpd_t:s0" ps_log -E || \
                rlLogInfo "$p's context is: \"$(cat ps_log|grep nginx|awk '{print $1}')\""
        done
    rlPhaseEnd

    rlPhaseStartCleanup
        rlRun "rlServiceStop $nginxHTTPD"
        rlRun "popd"
        rlRun "rm -r $TmpDir" 0 "Removing tmp directory"
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd
