## Process this file with Automake to produce Makefile.in

dist_bin_SCRIPTS = bin/stow bin/chkstow
info_TEXINFOS = doc/stow.texi
dist_man_MANS = doc/stow.8
dist_doc_DATA = README doc/manual.html doc/manual.pdf

# Would be nice to include the split page HTML version of the manual
# in the distribution, but automake doesn't support wildcards and I'm
# loathe to explicitly list every single page here :-(
#nobase_dist_doc_DATA = doc/stow.html/*.html

pmdir = $(libdir)/perl5
dist_pm_DATA = lib/Stow.pm
pmstowdir = $(pmdir)/Stow
dist_pmstow_DATA = lib/Stow/Util.pm

TEXINFO_TEX = doc/texinfo.tex
export TEXI2DVI_BUILD_MODE = clean
AM_MAKEINFOFLAGS = -I $(srcdir)

# We require this -I parameter to ensure that the include of the
# default ignore list in the manual works.  Unfortunately this is
# the only way to do it:
#
#   http://article.gmane.org/gmane.comp.sysutils.automake.bugs/4334/match=passing+parameters
#
# even though it annoyingly produces a warning with the -Wall option
# to AM_INIT_AUTOMAKE which has to be silenced via -Wno-override.
TEXI2DVI = texi2dvi $(AM_MAKEINFOFLAGS)

DEFAULT_IGNORE_LIST = $(srcdir)/default-ignore-list

TESTS_DIR = $(srcdir)/t
TESTS_OUT = tmp-testing-trees
TESTS_ENVIRONMENT = $(PERL) -I$(srcdir)/bin -I$(srcdir)/lib -I$(TESTS_DIR)

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
# `color-tests' AM_INIT_AUTOMAKE option .
#
# Note that automake's `check' rule cannot be overridden
# for some weird reason:
#
#   http://thread.gmane.org/gmane.comp.sysutils.automake.general/13040/focus=13041
#
# so we override check-TESTS instead which is where the real work is
# done anyway.  Unfortunately this produces a warning with the -Wall
# option to AM_INIT_AUTOMAKE which has to be silenced via
# -Wno-override.
check-TESTS:
	dir=$(TESTS_DIR); \
	$(TESTS_ENVIRONMENT) -MTest::Harness -e 'runtests(@ARGV)' "$${dir#./}"/*.t

$(TESTS_OUT):
	mkdir -p $@

CPAN_FILES = MANIFEST MANIFEST.SKIP Build.PL META.yml META.json
EXTRA_DIST = \
	bin/stow.in bin/chkstow.in lib/Stow.pm.in \
	$(TESTS) t/testutil.pm \
	$(TEXINFO_TEX) \
	$(DEFAULT_IGNORE_LIST) \
	$(CPAN_FILES)
CLEANFILES = $(bin_SCRIPTS) $(dist_pm_DATA)

# clean up auto-generated files
clean-local:
	-rm -rf $(TESTS_OUT) \
		bin/stow bin/chkstow doc/stow.8 ChangeLog \
		doc/manual.*

# this is more explicit and reliable than the config file trick
edit = sed -e 's|[@]PERL[@]|$(PERL)|g' \
	   -e 's|[@]VERSION[@]|$(VERSION)|g'

bin/stow: bin/stow.in Makefile
	[ -d bin ] || mkdir bin # required in vpath mode
	$(edit) < $< > $@
	chmod +x $@

bin/chkstow: bin/chkstow.in Makefile
	[ -d bin ] || mkdir bin # required in vpath mode
	$(edit) < $< > $@
	chmod +x $@

lib/Stow.pm: lib/Stow.pm.in Makefile $(DEFAULT_IGNORE_LIST)
	[ -d lib ] || mkdir lib # required in vpath mode
	( $(edit) < $<; cat $(DEFAULT_IGNORE_LIST) ) > $@

##############################################################################
# The below rules are only used by the developer.
##############################################################################

# It's conventional to generate $project.info, but it's also nicer to
# generate manual.html and manual.pdf (which ultimately go somewhere
# like /usr/share/doc/stow/) rather than stow.html and stow.pdf, to
# make it obvious that these files contain the manual.  So we have to
# jump through a few extra hoops.
doc/manual.texi: doc/stow.texi doc/version.texi
	[ -d doc ] || mkdir doc # required in vpath mode
	cp -p $< $@

doc/manual.pdf: doc/stow.pdf doc/version.texi
	[ -d doc ] || mkdir doc # required in vpath mode
	cp -p $< $@

# It's easier to calculate the absolute path to $(srcdir) rather than
# the relative path to it from the doc/ build subdirectory.
doc/manual.html: doc/manual.texi
	-rm -f $@
	srcdir=$$( cd $(srcdir); pwd ); \
	cd doc && texi2html -I $$srcdir -expandinfo -menu -monolithic -verbose manual.texi

doc/stow.8: bin/stow Makefile
	[ -d doc ] || mkdir doc # required in vpath mode
	pod2man $< > $@

