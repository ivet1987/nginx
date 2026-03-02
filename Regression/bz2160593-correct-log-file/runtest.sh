#!/bin/bash
# vim: dict+=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k

# Include Beaker environment
. /usr/share/beakerlib/beakerlib.sh || exit 1

PACKAGES=${PACKAGES:-"nginx"}

rlJournalStart
rlPhaseStartSetup
        rlAssertRpm --all
        rlRun "rlImport nginx/nginx"
        rlRun "TmpDir=\$(mktemp -d)" 0 "Creating tmp directory"
        rlRun "pushd $TmpDir"
        rlRun "rm -f /var/log/nginx/access*" 0 "Clearing access log"
        # Backup and remove SSL configuration to avoid password prompt on RHEL 9.7+
        # See BZ#2170808 - SSL keys are password-protected by default
        rlRun "rlFileBackup --namespace nginx_ssl /etc/nginx/conf.d/ssl.conf" 0,1
        rlRun "rm -f /etc/nginx/conf.d/ssl.conf" 0,1
        rlRun "rlServiceStart $nginxHTTPD"
        rlRun "set -o pipefail"
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
        # Restore SSL configuration if it was backed up
        rlRun "rlFileRestore --namespace nginx_ssl" 0,1
        rlRun "rlServiceStop $nginxHTTPD"
        rlRun "popd"
        rlRun "rm -r $TmpDir" 0 "Removing tmp directory"
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd
