#!/bin/bash
# vim: dict+=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   lib.sh of /CoreOS/nginx/Library/nginx
#   Description: library for testing nginx
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
#   library-prefix = nginx
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

true <<'=cut'
=pod

=head1 NAME

nginx/nginx - Basic library for nginx testing.

=head1 DESCRIPTION

This library provides basic functions for easy testing of nginx.
Main goal of this library is to simplify starting
http(s) server in various environments.

Library makes sure that no nginx server is running
before starting and after stopping web server.

If you find a bug in library or you want some changes or improvements, please
contact author.

=cut

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#   Variables
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

true <<'=cut'
=pod

=head1 VARIABLES

Below is the list of global variables which affect library's functions.

=over

=item nginxROOTDIR

Directory where web pages are stored.

=item nginxCONFDIR

Directory where nginx's config files and modules are stored.

=item nginxLOGDIR

Path to the directory where nginx logs are stored.

=item nginxNSS_DBDIR

Directory where mod_nss databases with certificates are stored.

=item nginxHTTPD

Name of web server's executable file.
This is also name of main rpm package.

=item nginxSSL_O

SSL oraganization name.
Default value is server's hostname.

=item nginxSSL_CN

SSL common name.
Default value is server's hostname.

=item nginxSSL_CRT

Path to server certificate (.crt).
Function nginxSecureStart will copy a certificate into this location.

=item nginxSSL_KEY

Path to private key to server certificate (.key).
Function nginxSecureStart will copy a private key into this location.

=item nginxSSL_PEM

Path to pem file with trusted certificates.
Default value is /etc/pki/tls/certs/ca-bundle.crt.
Certificate is available at http://SERVER_HOSTNAME/ca.crt
and function nginxInstallCa can download and install it into nginxSSL_PEM. 


=item nginxCOLLECTION

This variable indicates (0/1) whether nginx16 collection is enabled.

=item nginxCOLLECTION_NAME

Name of collection when using nginx from rhscl.

=item nginxROOTPREFIX

Prefix of web server root directory.
If running in nginx collection, it contains prefix of path to root directory,
for example "/opt/rh/nginx16/root".
If not in collection, this variable contains empty string

=back

=cut

export nginxROOTDIR=${nginxROOTDIR:-/usr/share/nginx/html}
export nginxROOTPREFIX=${nginxROOTPREFIX:-""}
export nginxCONFDIR=${nginxCONFDIR:-/etc/nginx}
#export nginxNSS_DBDIR=${nginxNSS_DBDIR:-/etc/nginx/alias}
export nginxHTTPD=${nginxHTTPD:-nginx}
export nginxSSL_CRT=${nginxSSL_CRT:-/etc/pki/tls/certs/localhost.crt}
export nginxSSL_KEY=${nginxSSL_KEY:-/etc/pki/tls/private/localhost.key}
export nginxSSL_PEM=${nginxSSL_PEM:-/etc/pki/tls/cert.pem}
export nginxSSL_O=${nginxSSL_O:-`hostname`}
export nginxSSL_CN=${nginxSSL_CN:-`hostname`}
export nginxLOGDIR=${nginxLOGDIR:-/var/log/nginx}
export nginxCOLLECTION=0
export nginxCOLLECTION_NAME=""

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#   Functions
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

true <<'=cut'
=pod

=head1 FUNCTIONS

=head2 nginxStart

Starts nginx server and create file $nginxROOTDIR/nginx_tesitfile
containging 'ok' string.

=head2 nginxStop

Stop nginx server and delete file $nginxROOTDIR/nginx_testfile.

=head2 nginxStatus

Check whether nginx server is running
by downloading http://SERVER_HOSTNAME/nginx_tesfile.

Returns 0 when nginx_testfile is successfully downloaded, 1 otherwise.

=head2 nginxSecureStart

Create self-signed SSL certificate, copy it into $nginxROOTDIR, create the file $nginxROOTDIR/nginx_testfile and start nginx service (restart if running) configured with HTTPS support.

=head2 nginxSecureStop

Stop nginx service, remove $nginxROOTDIR/nginx_testfile and restore SSL certificate file to the original state before the last nginxSecureStart call.

=head2 nginxSecureStatus

Check if nginx HTTPS server is running normally by downloading file https://SERVER_HOSTNAME/nginx_testfile.

Return 0 if nginx_testfile was successfully downloaded, 1 otherwise.

=head2 nginxInstallCa

Install certificate downloaded from SERVER_URL/ca.crt into local file with trusted CA's.

 nginxInstallCa SERVER_URL/ca.crt 

=head2 nginxRemoveCa

Remove installed CA by restoring the $nginxSSL_PERM file.

=head2 nginxVarExpand

Expand variables in specified configuration file. Only sequences in the form
%%VAR_NAME%% are taken for variables. Each variable %%VAR_NAME%% is replaced
with the contents of the corresponding environment variable $VAR_NAME.

 nginxVarExpand config_file

=over

=item config_file

Path to the configuration file in which variables are to be expanded. The result
is saved to the same file.

=back

=cut

__nginxKillNginx() {
    # make sure that no nginx process is running
    rlServiceStop $nginxHTTPD
    if ! ps -e --format comm  | grep -q '^nginx$';then
        return 0;
    fi
    if ps -e --format comm | grep -q '^nginx$';then
        rlLogWarning "nginx already running"
        rlLogInfo "`ps -e|grep 'nginx'`"
        #killall -q nginx
        sleep 5
    fi
    if ps -e --format comm  | grep -q '^nginx$';then
        killall -qs 9 nginx
        sleep 5
    fi
    for i in {1..10};do
        if ps -e --format comm  | grep -q '^nginx$';then
           sleep 5
       else
           rlLog "no nginx process is running now"
           break  # no nginx running, OK
        fi
    done
    if ps -e --format comm  | grep -q '^nginx$';then
        rlFail "nginx killing faild"
        rlLogInfo "`ps -e|grep 'nginx'`"
        return 1
    fi
}

nginxStart() {
    __nginxKillNginx
    # start server
    rlRun "rlServiceStart $nginxHTTPD" 0 "starting nginx service"|| return 1
    # create testfile
    rlRun "echo 'ok' > $nginxROOTDIR/nginx_testfile" 0 "Creating test file"
    return $?
}

nginxStop() {
    #remove testfile
    rlRun "rm -f $nginxROOTDIR/nginx_testfile" 0 "Deleting test file"

    # stop server
    rlRun "rlServiceStop $nginxHTTPD" 0 "stoping nginx service" || return 1

    __nginxKillNginx
    return 0
}

nginxStatus() {
    # ?? is this relevant test ??
    # try to download a testfile from running server
    local tmpdir
    local ret=0
    rlRun "tmpdir=`mktemp -d`" 0 "create tmp dir" || return 1
    rlRun "pushd $tmpdir"
    rlRun "wget --timeout=10 -t 2 -q http://`hostname`/nginx_testfile" 0 "download test file" || ret=1
    rlAssertGrep ok nginx_testfile || ret=1
    rlRun "popd"
    rlRun "rm -rf $tmpdir" 0 "remove tmp dir"
    return $ret
}

nginxsStart() {
    rlLogInfo "nginxsStart function is deprecated. Use nginxSecureStart instead."
    nginxSecureStart
}

nginxSecureStart() {
    __nginxKillNginx

    local tmpdir
    rlRun "tmpdir=`mktemp -d`" 0 "create tmp dir" || return 1
    rlRun "pushd $tmpdir"

    # prepare certificates
    rlRun "x509KeyGen ca" 0 "Creating CA key & certificate"
    rlRun "x509KeyGen server" 0 "Creating server key & certificate"
    rlRun "x509SelfSign ca --DN 'CN=test' --DN 'O=test'" \
        0 "Self-signing CA certificate"
    rlRun "x509CertSign --CA ca server --DN 'CN=$nginxSSL_CN' --DN 'O=$nginxSSL_O'" \
        0 "Signing server certificate"

    # backup certificates
    rlFileBackup --namespace nginx $nginxSSL_CRT
    rlFileBackup --namespace nginx $nginxSSL_KEY

    # copy certificates
    rlRun "cp -f $(x509Cert server) $nginxSSL_CRT"
    rlRun "cp -f $(x509Key server) $nginxSSL_KEY"

    # copy ca into nginx rootdir
    rlRun "cp -f $(x509Cert ca) $nginxROOTDIR/ca.crt" 0 "Copy ca.crt into $nginxROOTDIR"

    # start server
    rlRun "popd"
    rlRun "rm -rf $tmpdir"

    # create testfile
    rlRun "echo 'ok' > $nginxROOTDIR/nginx_testfile" 0 "Creating test file"

    # expand variables $nginxSSL_CRT and $nginxKEY in ssl.conf and apply the
    # new configuration
    local nginxSSLCONF=$nginxCONFDIR/conf.d/ssl.conf
    if rlIsRHEL '<=7'; then
        rlRun "cp $nginxLIBDIR/ssl.conf $nginxSSLCONF" 0 "Copying ssl.conf"
    else #rhel-8+
        rlRun "cp $nginxLIBDIR/ssl-rhel8.conf $nginxSSLCONF" 0 "Copying rhel8 ssl.conf"
    fi
    rlRun "nginxVarExpand $nginxSSLCONF"

    rlRun "rlServiceStart $nginxHTTPD" 0 "starting nginx service"
}

nginxsStop() {
    rlLogInfo "nginxsStop function is deprecated. Use nginxSecureStop instead."
    nginxSecureStop
}

nginxSecureStop() {
    rlRun "rlServiceStop $nginxHTTPD" 0 "stopping nginx service"

    # remove created files
    rlRun "rm -f $nginxSSL_CRT"
    rlRun "rm -f $nginxSSL_KEY"
    rlRun "rm -f $nginxROOTDIR/nginx_testfile"
    rlRun "rm -f $nginxROOTDIR/ca.crt"
    rlRun "rm -f $nginxCONFDIR/conf.d/ssl.conf"

    # restore certificates
    rlFileRestore --namespace nginx

    __nginxKillNginx
}

nginxsStatus() {
    rlLogInfo "nginxsStatus function is deprecated. Use nginxSecureStatus instead."
    nginxSecureStatus
}

nginxSecureStatus() {
    local tmpdir
    local ret=0
    rlRun "tmpdir=`mktemp -d`" 0 "create tmp dir" || return 1
    rlRun "pushd $tmpdir"
    rlRun "wget --timeout=10 -t 2 --ca-certificate $nginxSSL_PEM https://`hostname`/nginx_testfile" 0 "download test file" || ret=1
    rlAssertGrep ok nginx_testfile || ret=1
    rlRun "popd"
    rlRun "rm -rf $tmpdir" 0 "remove tmp dir"
    return $ret
}

nginxInstallCa() {
    # download ca.crt from server and add it into local file with trusted ca's
    local tmpdir
    local ret=0
    rlRun "tmpdir=`mktemp -d`" 0 "create tmp dir" || return 1
    rlRun "pushd $tmpdir"
    if [ -z $1 ];then
        rlFail "nginxInstallCa: no server url as argument"
        ret=1
    fi
    rlRun "wget --timeout=10 -t 2 $1/ca.crt" 0 "download certificate" || ret=1
    rlAssertExists ca.crt || ret=1

    rlRun "rlFileBackup --namespace nginx_ca $nginxSSL_PEM" 0 \
        "creating backup of $nginxSSL_PEM"
    rlRun "cat ca.crt >> $nginxSSL_PEM" 0 \
        "adding certificate to file with trusted ca's" || ret=1

    rlRun "popd"
    rlRun "rm -rf $tmpdir" 0 "remove tmp dir"
    return $ret
}

nginxRemoveCa() {
    # remove installed ca by restoring $nginxSSL_PEM file
    rlFileRestore --namespace nginx_ca
}

nginxVarExpand() {
    rlAssertExists $1 || return 1
    rlRun "perl -i -pe 's/%%(.*?)%%/\$ENV{\$1}/g' $1" 0 \
          "Expanding variables in file $1"
    return $?
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#   Execution
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

true <<'=cut'
=pod

=head1 EXECUTION

This library supports direct execution. When run as a task, phases
provided in the PHASE environment variable will be executed.
Supported phases are:

=over

=item Test

Run the self test suite.

=back

=cut

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#   Verification
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   This is a verification callback which will be called by
#   rlImport after sourcing the library to make sure everything is
#   all right.
#   In this case there is a test whether it is posible to start and stop nginx.

nginxLibraryLoaded() {
    ret=0
    # setup path variables if running in collection
    if echo $COLLECTIONS|grep "nginx";then
        nginxCOLLECTION_NAME=`echo $COLLECTIONS|grep -Eo '(rh-)?\bnginx[0-9]*\b'|tail -1`
        if [ "$nginxCOLLECTION_NAME" == "" ];then
            rlFail "Failed to detect nginx collection name"
            rlLog "COLLECTIONS=$COLLECTIONS"
            return 1
        fi
        nginxCOLLECTION=1
        nginxHTTPD=${nginxCOLLECTION_NAME}-nginx
        if echo $nginxCOLLECTION_NAME | grep '^rh-'; then
            # new collection, conf in /etc/opt/rh, logs in /var/opt/rh
            nginxCONFDIR=/etc/opt/rh/$nginxCOLLECTION_NAME/nginx
            nginxLOGDIR=/var/opt/rh/$nginxCOLLECTION_NAME/log/nginx
        else
            # old collection, conf in /opt/rh, logs in /var/log
            nginxCONFDIR=/opt/rh/$nginxCOLLECTION_NAME/root/etc/nginx
            nginxLOGDIR=/var/log/$nginxCOLLECTION_NAME
        fi
    fi
    rlRun "rpm -q $nginxHTTPD" 0 "checking $nginxHTTPD rpm"

    # setup path variables from configuration file
    rlRun "nginxROOTDIR_tmp=\$(grep '^[ \t]*root[ \t]*/' ${nginxCONFDIR}/nginx.conf|head -1|\
        awk '{print \$2}'|sed -e 's/\"//g;s/;//')" 0 "setup nginxROOTDIR"
    [ "$nginxROOTDIR_tmp" != "" ] && nginxROOTDIR=$nginxROOTDIR_tmp  # this is for preventing this var to be "" when detection from nginx.conf fails
    unset -v nginxROOTDIR_tmp
    if ! [ -d $nginxROOTDIR ]; then
        nginxROOTDIR=/dev/null  # this should be safe value for any potencionaly destructive tests
        rlFail "Library is unable to get document rootdir from configuration file: $nginxCONFDIR/nginx.conf"
        ret=1
    fi

    rlRun "nginxROOTPREFIX=\$(echo $nginxROOTDIR|sed -e 's/\/usr.*//')" 0 "parsing prefix from nginxROOTDIR"

    # follow symlinks to certificates
    rlRun "nginxSSL_CRT=\$(readlink -f $nginxSSL_CRT)" 0 "following posible symlink of $nginxSSL_CRT"
    rlRun "nginxSSL_KEY=\$(readlink -f $nginxSSL_KEY)" 0 "following posible symlink of $nginxSSL_KEY"
    rlRun "nginxSSL_PEM=\$(readlink -f $nginxSSL_PEM)" 0 "following posible symlink of $nginxSSL_PEM"

    # print variables
    #rlLogInfo "PACKAGES=$PACKAGES"
    #rlLogInfo "REQUIRES=$REQUIRES"
    rlLogInfo "COLLECTIONS=$COLLECTIONS"
    rlLogInfo "nginxCOLLECTION=$nginxCOLLECTION"
    rlLogInfo "nginxCOLLECTION_NAME=$nginxCOLLECTION_NAME"
    rlLogInfo "nginxHTTPD=$nginxHTTPD"
    rlLogInfo "nginxROOTDIR=$nginxROOTDIR"
    rlLogInfo "nginxROOTPREFIX=$nginxROOTPREFIX"
    rlLogInfo "nginxCONFDIR=$nginxCONFDIR"
    rlLogInfo "nginxLOGDIR=$nginxLOGDIR"
    rlLogInfo "nginxSSL_CRT=$nginxSSL_CRT"
    rlLogInfo "nginxSSL_KEY=$nginxSSL_KEY"
    rlLogInfo "nginxSSL_PEM=$nginxSSL_PEM"
    rlLogInfo "nginxSSL_O=$nginxSSL_O"
    rlLogInfo "nginxSSL_CN=$nginxSSL_CN"

    rlAssertExists $nginxROOTDIR
    rlAssertRpm $nginxHTTPD || ret=1
    # TODO: read paths to ssl certificates from config files?

    # Remember the path to the library in order to comfortably access the file
    # ssl.conf later (and possibly other files too in the future)
    nginxLIBDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

    return $ret
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#   Authors
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

true <<'=cut'
=pod

=head1 AUTHORS

=over

=item *

Ondrej Ptak <optak@redhat.com>

=back

=cut
