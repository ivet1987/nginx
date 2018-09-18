# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Makefile of /CoreOS/nginx/Regression/nginx-upstream-testsuite
#   Description: Upstream nginx test suite
#   Author: Joe Orton <jorton@redhat.com>
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Copyright (c) 2013 Red Hat, Inc. All rights reserved.
#
#   PROVIDE YOUR LICENSE TEXT HERE.
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

export TEST=/CoreOS/nginx/Regression/nginx-upstream-testsuite
export TESTVERSION=1.0

BUILT_FILES=

FILES=$(METADATA) runtest.sh Makefile PURPOSE whitelist.txt Config.pm

.PHONY: all install download clean

run: $(FILES) build
	./runtest.sh

build: $(BUILT_FILES)
	test -x runtest.sh || chmod a+x runtest.sh

clean:
	rm -f *~ $(BUILT_FILES)

include /usr/share/rhts/lib/rhts-make.include

$(METADATA): Makefile
	@echo "Owner:           Joe Orton <jorton@redhat.com>" > $(METADATA)
	@echo "Name:            $(TEST)" >> $(METADATA)
	@echo "TestVersion:     $(TESTVERSION)" >> $(METADATA)
	@echo "Path:            $(TEST_DIR)" >> $(METADATA)
	@echo "Description:     Upstream nginx test suite" >> $(METADATA)
	@echo "Type:            Regression" >> $(METADATA)
	@echo "TestTime:        10m" >> $(METADATA)
	@echo "RunFor:          nginx" >> $(METADATA)
	@echo "Requires:        nginx" >> $(METADATA)
	@echo "Requires:        perl-Test-Simple perl-Test-Harness perl-CPAN perl-Module-Build perl-Net-SSLeay perl-FCGI" >> $(METADATA)
	@echo "Requires:        python-devel" >> $(METADATA)
	@echo "Priority:        Normal" >> $(METADATA)
	@echo "License:         BSD" >> $(METADATA)
	@echo "Confidential:    yes" >> $(METADATA)
	@echo "Destructive:     no" >> $(METADATA)

	rhts-lint $(METADATA)
