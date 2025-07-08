#!/bin/bash
# vim: dict=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /CoreOS/nginx/Regression/bz1065981-redhat-in-error-pages
#   Description: check 404.html and 50x.html, there should be Red Hat, not Fedora
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
NGINX_VER=$(rpm -q --qf "%{VERSION}\n" nginx)

rlJournalStart
    rlPhaseStartSetup
        rlAssertRpm --all
        rlRun "rlImport nginx/nginx"
        NGINX_HTML_DIR=$nginxROOTPREFIX/usr/share/nginx/html/
        rlRun "TmpDir=\$(mktemp -d)" 0 "Creating tmp directory"
        rlRun "pushd $TmpDir"
    rlPhaseEnd

    rlPhaseStartTest
	rlRun "PAGES=index.html 50x.html"
	rlTestVersion $NGINX_VER "<=" 1.24.0 && PAGES="$PAGES 404.html"
	for page in $PAGES; do
            rlAssertNotGrep "Fedora" $NGINX_HTML_DIR/$page
            rlAssertGrep "Red Hat" $NGINX_HTML_DIR/$page
        done
    rlPhaseEnd

    rlPhaseStartCleanup
        rlRun "popd"
        rlRun "rm -r $TmpDir" 0 "Removing tmp directory"
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd
