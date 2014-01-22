#!/bin/bash
# vim: dict=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /CoreOS/nginx/Regression/bz1052935-selinux-context-of-nginx14-nginx
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
. /usr/bin/rhts-environment.sh || exit 1
. /usr/share/beakerlib/beakerlib.sh || exit 1

PACKAGES=${PACKAGES:-"nginx14-nginx"}

rlJournalStart
    rlPhaseStartSetup
        rlAssertRpm --all
        rlRun "TmpDir=\$(mktemp -d)" 0 "Creating tmp directory"
        rlRun "pushd $TmpDir"
        rlRun "NGINX_VER=\$(echo $COLLECTIONS|grep nginx)" 0 "getting version of nginx collection"
        rlRun "NGINX_RPM=$NGINX_VER-nginx"
    rlPhaseEnd

    rlPhaseStartTest
        rlRun "ls -d --scontext \$(rpm -ql $NGINX_RPM) > files_context.log"\
            0 "getting selinux context of rpm's files"
        rlAssertNotGrep "initrc_t" files_context.log
        rlAssertGrep "httpd_exec_t.*/usr/sbin/nginx" files_context.log
        rlAssertGrep "httpd_config_t.*/etc/nginx" files_context.log
        rlAssertGrep "httpd_log_t.*/var/log/nginx" files_context.log
        rlAssertGrep "httpd_var_lib_t.*/var/lib/nginx" files_context.log
        rlAssertGrep "httpd_log_t.*/var/log/nginx" files_context.log
        rlAssertGrep "httpd_var_run_t.*/var/run/nginx" files_context.log
    rlPhaseEnd

    rlPhaseStartCleanup
        rlRun "popd"
        rlRun "rm -r $TmpDir" 0 "Removing tmp directory"
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd
