#!/bin/bash
# vim: dict=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /CoreOS/nginx/Regression/bz1052935-selinux-context-of-nginx
#   Description: check context of rpm's files
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
. /usr/share/beakerlib/beakerlib.sh || exit 1

PACKAGES=${PACKAGES:-"nginx"}

rlJournalStart
    rlPhaseStartSetup
        rlAssertRpm --all
        rlRun "rlImport nginx/nginx"
        rlRun "TmpDir=\$(mktemp -d)" 0 "Creating tmp directory"
        rlRun "pushd $TmpDir"
    rlPhaseEnd

    rlPhaseStartTest
        rlRun "ls -dZ \$(rpm -ql $nginxHTTPD) > files_context.log"\
            0 "getting selinux context of rpm's files"
        if rlIsRHEL ">=9" ; then
            rlRun "ls -dZ \$(rpm -ql nginx-core) >> files_context.log"\
            0 "getting selinux context of rpm's files"
        fi
        rlAssertNotGrep ":initrc_exec_t" files_context.log
        if rlIsRHEL 6; then
            rlAssertGrep ":httpd_initrc_exec_t.*/etc/rc.d/init.d/$nginxHTTPD" \
                files_context.log
        fi
        rlAssertGrep ":httpd_exec_t.*$(which nginx)" files_context.log
        rlAssertGrep ":httpd_config_t.*$nginxCONFDIR" files_context.log
        rlAssertGrep ":httpd_log_t.*$nginxLOGDIR" files_context.log

        if [[ $nginxCOLLECTION_NAME =~ ^rh- ]]; then
            nginxLIBDIR="/var/opt/rh/$nginxCOLLECTION_NAME/lib"
            nginxRUNDIR="/var/opt/rh/$nginxCOLLECTION_NAME/run"
        else
            nginxLIBDIR="$nginxROOTPREFIX/var/lib/nginx"
            nginxRUNDIR="$nginxROOTPREFIX/var/run/nginx"
        fi

        rlAssertGrep ":httpd_var_lib_t.*$nginxLIBDIR" files_context.log
	if rlIsRHEL '<8'; then
            rlAssertGrep ":httpd_var_run_t.*$nginxRUNDIR" files_context.log
        fi
        cat files_context.log
    rlPhaseEnd

    rlPhaseStartCleanup
        rlRun "popd"
        rlRun "rm -r $TmpDir" 0 "Removing tmp directory"
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd
