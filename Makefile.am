## Process this file with Automake to produce Makefile.in

dist_bin_SCRIPTS = bin/stow bin/chkstow
info_TEXINFOS = doc/stow.texi
dist_man_MANS = doc/stow.8
dist_doc_DATA = \
	README \
	doc/manual.pdf doc/manual-single.html doc/version.texi \
	ChangeLog doc/ChangeLog.OLD

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

doc_deps = $(info_TEXINFOS) doc/version.texi

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
# `color-tests' AM_INIT_AUTOMAKE option.  This also dodges having to
# set TESTS to the full list of tests, which is good because automake
# doesn't support wildcards, and so it would be too easy to forget to
# add a new one to the list.
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
	doc/manual-split \
	$(TESTS) t/testutil.pm \
	$(TEXINFO_TEX) \
	$(DEFAULT_IGNORE_LIST) \
	$(CPAN_FILES)
CLEANFILES = $(bin_SCRIPTS) $(dist_pm_DATA)

# clean up auto-generated files
clean-local:
	-rm -rf $(TESTS_OUT) \
		bin/stow bin/chkstow doc/stow.8 ChangeLog \
		doc/manual-split doc/manual-single.html doc/manual.pdf

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
# The below rules should only be needed by developers.
##############################################################################

doc/stow.8: bin/stow Makefile
	[ -d doc ] || mkdir doc # required in vpath mode
	pod2man $< > $@

# We use automake's built-in rule to generate stow.info.  The built-in
# rules would also generate doc/stow.html and doc/stow.pdf, but after
# installation we want $(docdir) (typically /usr/share/doc/stow/) to
# contain manual-single.html, manual.pdf, and manual-split/*.html, to
# make it explicitly obvious that these files contain the user manual
# rather than some other Stow-related documentation.
#
# If it were not for a troublesome dependency on doc/$(am__dirstamp):
#
#   http://article.gmane.org/gmane.comp.sysutils.automake.general/13192
#
# we could have achieved this using the built-in rules combined with
# install-data-hook to rename from stow.pdf to manual.pdf etc. on
# install.  Instead, by overriding the built-in rules with modified
# versions, we can kill both birds with one stone.

doc/manual-single.html: $(doc_deps)
	[ -d doc ] || mkdir doc # required in vpath mode
	-rm -f $@
	texi2html --P=$(srcdir) --output=$@ -expandinfo -menu -monolithic -verbose $<

doc/manual.pdf: $(doc_deps)
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
doc/manual-single.html: doc/manual-split

# With the above hack, this probably isn't necessary but is safer to
# keep in anyway:
dist-hook: doc/manual-split

ChangeLog: doc/ChangeLog.OLD Makefile
	@if [ -d .git ]; then \
	    ( \
	        git log \
		    --format="format:%ad  %aN <%aE>%n%n    * %w(70,0,4)%s%+b%n" \
		    --name-status \
		    v2.0.2..HEAD \
                | sed 's/^\([A-Z]\)\t/      \1 /'; \
	        cat $< \
	    ) > $@; \
	else \
	    echo "Not in a git repository; can't update ChangeLog."; \
	fi
