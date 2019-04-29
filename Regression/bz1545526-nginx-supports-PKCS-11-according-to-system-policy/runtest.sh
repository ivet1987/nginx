#!/bin/bash
# vim: dict+=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /CoreOS/nginx/Regression/bz1545526-nginx-supports-PKCS-11-according-to-system-policy
#   Description: Test for BZ#1545526 (nginx supports PKCS#11 according to system policy)
#   Author: Jan Houska <jhouska@redhat.com>  adapted from
#   TC#571234 /CoreOS/p11-kit/Integration/httpd-pkcs11-uri of <szidek@redhat.com>
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Copyright (c) 2018 Red Hat, Inc.
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

PIN=123456
TOKENLABEL="softhsm"
LABEL="nginx"


rlJournalStart
    rlPhaseStartSetup
        rlRun "rlImport nginx/nginx" || rlDie
        rlRun "rlImport openssl/certgen" || rlDie

        rlAssertRpm --all

        nginxSSLCONF=${nginxCONFDIR}/conf.d/bz1545526.conf

        rlRun "rlFileBackup --namespace softhsm-namesp --clean /var/lib/softhsm/tokens/"
        rlRun "rlFileBackup --namespace nginx-root-namesp  --clean $nginxROOTDIR"
        rlRun "rlFileBackup --namespace nginx-conf-namesp  $nginxCONFDIR"

        ## preparing configuration
        echo "Testing PKCS #11 support" > ${nginxROOTDIR}/index.html
        rlRun "cp bz1545526.conf ${nginxSSLCONF}"

        # This adds nginx to "ods" group allowing it to modify /var/lib/softhsm/tokens
        # This must be done only for testing purposes
        rlRun "usermod -a -G ods nginx"

        rlRun "TmpDir=\$(mktemp -d)" 0 "Creating tmp directory"
        rlRun "pushd $TmpDir"

        # Change SELinux label to allow nginx to create tokens/keys
        rlRun "chcon -R -t httpd_sys_rw_content_t /var/lib/softhsm/tokens"

        nginxdir=$nginxCONFDIR/certificates
        rlRun "mkdir $nginxdir"
        rlRun "pushd $nginxdir"
        rlRun "x509KeyGen ca"
        rlRun "x509SelfSign ca"
        rlRun "x509KeyGen localhost"
        rlRun "x509CertSign --CA ca localhost"
        rlRun "chown -R nginx:nginx *"

        serverkey="$PWD/$(x509Key localhost)"
        servercert="$PWD/$(x509Cert localhost)"
        cacert="$PWD/$(x509Cert ca)"
        rlRun "runuser -u nginx -- softhsm2-util --init-token --free --label $TOKENLABEL --pin $PIN --so-pin $PIN"
        rlRun "popd"
    rlPhaseEnd


     rlPhaseStartTest "Import key and cert to softhsm token"
        rlRun -s "runuser -u nginx -- p11tool --list-tokens"
        rlAssertGrep "$TOKENLABEL" $rlRun_LOG
        TOKENURL=$(cat $rlRun_LOG |grep "URL:.*token=$TOKENLABEL" |awk '{ print $NF }')

        ## write and list key
        rlRun "runuser -u nginx -- p11tool --write --load-privkey $serverkey --label $LABEL --login --set-pin $PIN $TOKENURL"
        rlRun -s "runuser -u nginx -- p11tool --login --set-pin $PIN --list-keys $TOKENURL"
        rlAssertGrep "URL:.*object=$LABEL;type=private" $rlRun_LOG
        KEYURL=$(cat $rlRun_LOG |grep "URL:.*object=$LABEL;type=private" |awk '{ print $NF }')?pin-value=$PIN

        ## write and list cert
        #rlRun "runuser -u nginx -- p11tool --write --load-certificate $servercert --label $LABEL --login --set-pin $PIN $TOKENURL"
        #rlRun -s "runuser -u nginx -- p11tool --list-all-certs $TOKENURL"
        #rlAssertGrep "URL:.*object=$LABEL;type=cert" $rlRun_LOG
        #CERTURL=$(cat $rlRun_LOG |grep "URL:.*object=$LABEL;type=cert" |awk '{ print $NF }')

        rm -f $rlRun_LOG
    rlPhaseEnd


    rlPhaseStartTest  "Test nginx"
        # Configure nginx to use certificate and key stored in HSM (softhsm)
        #rlRun "sed -i 's/ssl_certificate .*\$/ssl_certificate \"$CERTURL\";/' $nginxSSLCONF"
        rlRun "sed -i 's/ssl_certificate_key.*\$/ssl_certificate_key \"engine:pkcs11:$KEYURL\";/' $nginxSSLCONF"
        rlRun "cat $nginxSSLCONF" 0 "Show ssl config file"
        rlRun "rlServiceStart $nginxHTTPD"
        rlRun "rlWaitForSocket 443 -t 5"

        rlRun -s "curl -v -sS --cacert $cacert https://localhost" 0
        rlAssertGrep "Testing PKCS #11 support" $rlRun_LOG
        rm -f $rlRun_LOG
    rlPhaseEnd


    rlPhaseStartCleanup
        rlRun "rlServiceStop $nginxHTTPD"
        rlRun "rm -fr $nginxdir" 0 "Removing certificates"
        rlRun "rm -f ${nginxSSLCONF}" 0 "Removing nginx ssl config file"
        rlRun "rlFileRestore --namespace nginx-root-namesp" 0 "Restoring files"
        rlRun "rlFileRestore --namespace nginx-conf-namesp" 0 "Restoring files"
        rlRun "rlFileRestore --namespace softhsm-namesp" 0 "Restoring files"
        rlRun "popd"
        rlRun "rm -r $TmpDir" 0 "Removing tmp directory"
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd
