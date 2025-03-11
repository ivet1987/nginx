#!/bin/bash
ECODE=

TMT_RUN_ID=$(mktemp -d /var/tmp/tmt/run-imagemode-XXXX)
tmt run --id ${TMT_RUN_ID} discover -v provision --how minute --flavor ocp-master --image Fedora-41 plans --name /bootc/Jachym prepare -v execute -v finish -v
ECODE=$?
mkdir -p /var/tmp/tmt/testcloud
yq -i '.plans = [ "/bootc/Jachym", "/bootc/stroj" ]' ${TMT_RUN_ID}/run.yaml
mv ${TMT_RUN_ID}/bootc/Jachym/data/stroj-tmt-run/stroj ${TMT_RUN_ID}/bootc/
tmt run --id ${TMT_RUN_ID} report -h html -f

exit ${ECODE}
