#!/bin/bash
# vim: dict+=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /CoreOS/nginx/Regression/bz1264342-Miscellaneous-rh-nginx18-man-page-issues
#   Description: Test for BZ#1264342 (Miscellaneous rh-nginx18 man page issues)
#   Author: Jakub Heger <jheger@redhat.com>
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Copyright (c) 2017 Red Hat, Inc.
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

set -o pipefail

PACKAGES="${PACKAGES:-nginx}"

rlJournalStart
    rlPhaseStartSetup
        rlAssertRpm --all
        rlRun "TmpDir=\$(mktemp -d)" 0 "Creating tmp directory"
        rlRun "pushd $TmpDir"
    rlPhaseEnd

    rlPhaseStartTest
        rlRun "man_path=$(man -w $(echo $COLLECTIONS | grep nginx))" 0 "Getting manpath to package"
        rlAssertExists $man_path
        rlRun "cp $man_path ." 0 "Copying manpage to TmpDir $TmpDir"
        rlRun "man_file=${man_path##*/}" 0 "Cutting the file name"
        rlRun "gunzip $man_file" 0 "Unpacking man page"
        rlRun "unpacked_file=${man_file%.gz*}"
        cat $unpacked_file
        # Possible breakable line, delete if cause trouble
        rlAssertNotGrep "frh-nginx" $unpacked_file
        rlRun "grep \"scl\senable\s.*-arg\" $unpacked_file | wc -l | tee num_of_occurrences" 0 "Counting number of occurrences of regex"
        if grep -v "1" ./num_of_occurrences; then 
            rlFail "More/less than 1 occurences of string found"
        else 
            rlPass "Once occurrence od string found"
        fi
        #rlRun "count=$(grep scl\senable\s.*\\-\\-arg $unpacked_file | wc -l)" 0 "Counting number of occurrences of regex"
    rlPhaseEnd

    rlPhaseStartCleanup
        rlRun "popd"
        rlRun "rm -r $TmpDir" 0 "Removing tmp directory"
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd
