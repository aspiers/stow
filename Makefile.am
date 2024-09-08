# This file is part of GNU Stow.
#
# GNU Stow is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# GNU Stow is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see https://www.gnu.org/licenses/.

## Process this file with Automake to produce Makefile.in

bin_SCRIPTS = bin/stow bin/chkstow
info_TEXINFOS = doc/stow.texi
dist_man_MANS = doc/stow.8
PDF = doc/manual.pdf
HTML = doc/manual-single.html
dist_doc_DATA = \
	README.md INSTALL.md \
	$(HTML) doc/version.texi \
	ChangeLog doc/ChangeLog.OLD

# automake magic to define where *_DATA files get installed:
pmdir = $(PMDIR)
pmstowdir = $(pmdir)/Stow

pm_DATA = lib/Stow.pm
pmstow_DATA = lib/Stow/Util.pm

export TEXI2DVI_BUILD_MODE = clean
AM_MAKEINFOFLAGS = -I $(srcdir)

# We require this -I parameter to ensure that the include of the
# default ignore list in the manual works correctly, even when the
# manual is being built via make distcheck from a different directory.
# Unfortunately this is the only way to do it:
#
#   https://lists.gnu.org/archive/html/bug-automake/2008-09/msg00040.html
#
# even though it annoyingly produces a warning with the -Wall option
# to AM_INIT_AUTOMAKE which has to be silenced via -Wno-override.
TEXI2DVI = texi2dvi $(AM_MAKEINFOFLAGS)

DEFAULT_IGNORE_LIST = $(srcdir)/default-ignore-list

doc_deps = $(info_TEXINFOS) doc/version.texi $(DEFAULT_IGNORE_LIST)

TESTS_DIR = $(srcdir)/t
TESTS_OUT = tmp-testing-trees tmp-testing-trees-compat
TESTS_ENVIRONMENT = $(PERL) -Ibin -Ilib -I$(TESTS_DIR)

# This is a kind of hack; TESTS needs to be set to ensure that the
# `check-am' target makes check-TESTS, but we override check-TESTS
# so it doesn't really matter what it's set to, as long as it already
# exists (otherwise automake will try to build it).
TESTS = t

# GNU autotools standardised on the 'check' target, but CPAN (and the
# rest of the world) standardised on the 'test' target.
test: check

# required in vpath mode to ensure $build/t/ exists
check_DATA = $(TESTS_OUT)

# Test::Harness produces cleaner output than automake's default test
# harness, albeit without the pretty colours provided by the
# `color-tests' AM_INIT_AUTOMAKE option.  This also dodges having to
# set TESTS to the full list of tests, which is good because automake
# doesn't support wildcards, and so it would be too easy to forget to
# add a new one to the list.
#
# Note that automake's `check' rule cannot be overridden
# for some weird reason:
#
#   https://lists.gnu.org/archive/html/automake/2011-09/msg00029.html
#
# so we override check-TESTS instead which is where the real work is
# done anyway.  Unfortunately this produces a warning with the -Wall
# option to AM_INIT_AUTOMAKE which has to be silenced via
# -Wno-override.
check-TESTS:
	dir=$(TESTS_DIR); \
	$(TESTS_ENVIRONMENT) -MTest::Harness -e 'runtests(@ARGV)' "$${dir#./}"/*.t

coverage:
	PERL5OPT=-MDevel::Cover $(MAKE) check-TESTS
	cover

$(TESTS_OUT):
	mkdir -p $@

CPAN_FILES = MANIFEST MANIFEST.SKIP Build.PL META.yml META.json
EXTRA_DIST = \
	bin/stow.in bin/chkstow.in lib/Stow.pm.in lib/Stow/Util.pm.in \
	$(PDF) doc/manual-split \
	$(TESTS) t/testutil.pm \
	$(DEFAULT_IGNORE_LIST) \
	$(CPAN_FILES)
CLEANFILES = $(bin_SCRIPTS) $(pm_DATA) $(pmstow_DATA)
DISTCLEANFILES = Makefile.in configure Build MYMETA.*
MAINTAINERCLEANFILES = $(dist_man_MANS) $(HTML) $(PDF) ChangeLog

# clean up auto-generated files
clean-local:
	-rm -rf $(TESTS_OUT)
maintainer-clean-local:
	-rm -rf doc/manual-split cover_db

# this is more explicit and reliable than the config file trick
edit = sed -e 's|[@]PERL[@]|$(PERL)|g'       \
	   -e 's|[@]VERSION[@]|$(VERSION)|g' \
	   -e "s|[@]USE_LIB_PMDIR[@]|$$use_lib_pmdir|g"

pmdir_in_INC = \
	PERL5LIB= $(PERL) -V | \
	    awk '/@INC/ {p=1; next} p==1 {print $$1}' | \
	    grep -q "$(pmdir)"

calc_use_lib_pmdir = \
	if $(pmdir_in_INC); then \
	    use_lib_pmdir=""; \
	else \
	    use_lib_pmdir="use lib \"$(pmdir)\";"; \
	fi

check_pmdir = \
	echo; \
	echo "\# Perl modules will be installed to $(pmdir)"; \
	echo "\# "; \
	if $(pmdir_in_INC); then \
	    echo "\# This is in $(PERL)'s built-in @INC, so everything"; \
	    echo "\# should work fine with no extra effort."; \
	else \
	    echo "\# This is not in $(PERL)'s built-in @INC, so the"; \
	    echo "\# front-end scripts will have an appropriate \"use lib\""; \
	    echo "\# line inserted to compensate."; \
	fi; \
	echo

bin/stow: bin/stow.in Makefile.am
	[ -d bin ] || mkdir bin # required in vpath mode
	@$(check_pmdir)
	@$(calc_use_lib_pmdir); \
	$(edit) < $< > $@
	@echo "Generated $@ from $<"
	chmod +x $@

bin/chkstow: bin/chkstow.in Makefile.am
	@[ -d bin ] || mkdir bin # required in vpath mode
	@$(edit) < $< > $@
	@echo "Generated $@ from $<"
	chmod +x $@

lib/Stow.pm: lib/Stow.pm.in $(DEFAULT_IGNORE_LIST) Makefile.am
	@[ -d lib ] || mkdir lib # required in vpath mode
	@( $(edit) < $<; cat $(DEFAULT_IGNORE_LIST) ) > $@
	@echo "Generated $@ from $< and $(DEFAULT_IGNORE_LIST)"

lib/Stow/Util.pm: lib/Stow/Util.pm.in Makefile.am
	@[ -d lib/Stow ] || mkdir -p lib/Stow # required in vpath mode
	@$(edit) < $< > $@
	@echo "Generated $@ from $<"

##############################################################################
# The below rules should only be needed by developers.
##############################################################################

cpanm:
	cpanm --quiet --installdeps --notest .; \
	CPANM_RESULT=$$?; \
	if [ $$CPANM_RESULT != 0 ]; then \
	    echo ---------------------------------------------------; \
	    cat ~/.cpanm/build.log; \
	    echo ---------------------------------------------------; \
	    exit $$CPANM_RESULT; \
	fi

doc/stow.8: bin/stow.in Makefile.am
	[ -d doc ] || mkdir doc # required in vpath mode
	$(edit) < $< | pod2man --name stow --section 8 > $@

# We use automake's built-in rule to generate stow.info.  The built-in
# rules would also generate doc/stow.html and doc/stow.pdf, but after
# installation we want $(docdir) (typically /usr/share/doc/stow/) to
# contain manual-single.html, manual.pdf, and manual-split/*.html, to
# make it explicitly obvious that these files contain the user manual
# rather than some other Stow-related documentation.
#
# If it were not for a troublesome dependency on doc/$(am__dirstamp):
#
#   https://lists.gnu.org/archive/html/automake/2011-11/msg00107.html
#
# we could have achieved this using the built-in rules combined with
# install-data-hook to rename from stow.pdf to manual.pdf etc. on
# install.  Instead, by overriding the built-in rules with modified
# versions, we can kill both birds with one stone.

# Generating the single-page HTML version used to be done with the old
# texi2html, which is no longer maintained.  This rule is not used,
# but is kept to allow comparing of results during the transition, and
# potentially longer for posterity.
doc/manual-single-old-texi2html.html: $(doc_deps)
	texi2html --P=$(srcdir) --output=$@ -expandinfo -menu -monolithic -verbose $<

# One alternative to the old texi2html approach is to use the texi2html
# wrapper around texi2any which is provided as a partial drop-in replacement:
#
# https://www.gnu.org/software/texinfo/manual/texinfo/html_node/texi2html.html#texi2html
#
# Differences to the old texi2html:
#
#   - Doesn't wrap @file{foo} paths with quotes, which looks better.
#   - Missing certain sections
doc/manual-single-texi2html-wrapper.html: $(doc_deps)
	texi2any -P $(srcdir) --output=$@ --verbose \
		-c TEXI2HTML=1 -c SHOW_MENU=1 -c MONOLITHIC=1 $<

.PHONY: manual-single-html-all
manual-single-html-all: \
	$(HTML) \
	doc/manual-single-texi2html-wrapper.html \
	doc/manual-single-old-texi2html.html

# Modern approach using $(MAKEINFOHTML) --no-split
# Differences to the older two approaches:
#
#   - Nicer navigation links between sections
$(HTML): $(doc_deps)
	[ -d doc ] || mkdir doc # required in vpath mode
	-rm -f $@
	$(MAKEINFOHTML) $(AM_MAKEINFOHTMLFLAGS) $(MAKEINFOFLAGS) -I doc -I $(srcdir)/doc \
		-c USE_TITLEPAGE_FOR_TITLE=1 --no-split -o $@ \
		`test -f 'doc/stow.texi' || echo '$(srcdir)/'`doc/stow.texi

pdf: $(PDF)

$(PDF): $(doc_deps)
	TEXINPUTS="$(am__TEXINFO_TEX_DIR)$(PATH_SEPARATOR)$$TEXINPUTS" \
	MAKEINFO='$(MAKEINFO) $(AM_MAKEINFOFLAGS) $(MAKEINFOFLAGS) -I doc -I $(srcdir)/doc' \
	$(TEXI2PDF) -o $@ `test -f 'doc/stow.texi' || echo '$(srcdir)/'`doc/stow.texi

doc/manual-split: $(doc_deps)
	rm -rf $@.new
	if $(MAKEINFOHTML) $(AM_MAKEINFOHTMLFLAGS) $(MAKEINFOFLAGS) -I doc -I $(srcdir)/doc \
	 -o $@.new `test -f 'doc/stow.texi' || echo '$(srcdir)/'`doc/stow.texi; \
	then \
	  rm -rf $@; \
	  mv $@.new $@; \
	else \
	  rm -Rf $@.new $@; \
	  exit 1; \
	fi

# The split version of the manual is copied to $(docdir)/manual-split
# by install-data-hook.  The whole subdirectory is included via
# EXTRA_DIST in order to avoid having to list each file explicitly in
# dist_doc_DATA, since automake doesn't support wildcards, and
# dist_doc_DATA cannot refer to directories while EXTRA_DIST can (go
# figure ...)

install-data-hook: doc/manual-split
	cp -r $(srcdir)/doc/manual-split $(DESTDIR)$(docdir)

uninstall-hook:
	chmod u+w -R $(DESTDIR)$(docdir)/manual-split
	rm -rf $(DESTDIR)$(docdir)/manual-split

# Using install-data-hook has the slightly annoying disadvantage that
# by default the split version of the manual isn't automatically
# rebuilt during development by a simple `make'.  A workaround hack
# for this is to piggy-back the dependency onto manual-single.html,
# which *is* automatically rebuilt by `make':
$(HTML): doc/manual-split

# With the above hack, this probably isn't necessary but is safer to
# keep in anyway:
dist-hook: doc/manual-split

dist-hook: $(dist_man_MANS)
## If we are creating a distribution from a git checkout, ensure
## the ChangeLog file is in sync the git repository.
	if test -d $(top_srcdir)/.git; then \
	  rm -f ChangeLog \
	    && $(MAKE) $(AM_MAKEFLAGS) ChangeLog \
	    && cp -f ChangeLog $(distdir)/ChangeLog; \
	fi

ChangeLog: doc/ChangeLog.OLD
	@if [ -d .git ]; then \
	    ( \
	        git log \
		    --format="format:%ad  %aN <%aE>%n%n    * %w(70,0,4)%s%+b%n" \
		    --name-status \
		    v2.0.2..HEAD \
                | sed 's/^\([A-Z]\)\t/      \1 /'; \
	        cat $< \
	    ) > $@; \
	    echo "Rebuilt $@ from git commit history."; \
	else \
	    echo "Not in a git repository; can't update ChangeLog."; \
	fi

# Watch for changes, and if any rebuilds are required, also do a
# make install.
#
# If we solved https://github.com/aspiers/stow/issues/84, we could
# probably ditch this:
watch:
	@echo "Watching for changes to program source files ..."
	@while true; do \
	    if $(MAKE) 2>&1 | \
		grep -vE 'make\[[1-9]\]: (Entering|Leaving) directory ' | \
		grep -v 'Nothing to be done'; \
	    then \
		echo; \
		echo "-----------------------------------------------------"; \
		echo "make found things to rebuild; doing $(MAKE) install ..."; \
		echo; \
		$(MAKE) install; \
		echo; \
		echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"; \
		echo; \
	    fi; \
	    sleep 1; \
	done 2>&1 | \
	grep -vE 'make\[[1-9]\]: (Entering|Leaving) directory '
