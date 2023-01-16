#!/bin/bash
# vim: dict+=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
. /usr/share/beakerlib/beakerlib.sh || exit 1

rlJournalStart
    rlPhaseStartSetup
        rlRun "tmp=\$(mktemp -d)" 0 "Create tmp directory"
        rlRun "pushd $tmp"
        rlRun "set -o pipefail"
        rlServiceStart nginx
        rlFileBackup /var/log/nginx
    rlPhaseEnd

    rlPhaseStartTest
        rlRun "curl -s http://127.0.0.1/ > /dev/null" 0 "Access nginx server to create log line"
        rlRun "[ '$(cat /var/log/nginx/access.log | wc -l)' -eq '1' ]" 0 "verify that the log is there"
        rlRun "logrotate -f /etc/logrotate.d/nginx" 0 "forcing logrotate"
        rlRun "[ '$(ls /var/log/nginx/access* | wc -l)' -eq '2' ]" 0 "verify that rotation happened"
        rlRun "curl -s http://127.0.0.1/ > /dev/null" 0 "Access nginx server to create log line"
        rlRun "[ '$(cat /var/log/nginx/access.log | wc -l)' -eq '1' ]" 0 "verify that the log is in new file"
    rlPhaseEnd

    rlPhaseStartCleanup
        rlServiceRestore nginx
        rlFileRestore
        rlRun "popd"
        rlRun "rm -r $tmp" 0 "Remove tmp directory"
    rlPhaseEnd
rlJournalEnd
