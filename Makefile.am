## Process this file with Automake to produce Makefile.in

dist_bin_SCRIPTS = bin/stow bin/chkstow
info_TEXINFOS = doc/stow.texi
TEXINFO_TEX = doc/texinfo.tex
dist_man_MANS = doc/stow.8
dist_doc_DATA = README
pmdir = $(libdir)/perl5
dist_pm_DATA = lib/Stow.pm
pmstowdir = $(pmdir)/Stow
dist_pmstow_DATA = lib/Stow/Util.pm

DEFAULT_IGNORE_LIST = default-ignore-list

TESTS_ENVIRONMENT=$(PERL) -I $(top_srcdir)
TESTS = \
	t/cleanup_invalid_links.t  \
	t/defer.t                  \
	t/examples.t               \
	t/find_stowed_path.t       \
	t/foldable.t               \
	t/ignore.t                 \
	t/parent.t                 \
	t/stow_contents.t          \
	t/stow.t                   \
	t/unstow_contents_orig.t   \
	t/unstow_contents.t 	   \
	t/chkstow.t

AUTOMAKE_OPTIONS = dist-shar
CPAN_FILES = MANIFEST MANIFEST.SKIP Build.PL META.yml META.json
EXTRA_DIST = \
	bin/stow.in bin/chkstow.in lib/Stow.pm.in \
	$(TESTS) t/testutil.pm \
	$(TEXINFO_TEX) \
	default-ignore-list \
	$(CPAN_FILES)
CLEANFILES = $(bin_SCRIPTS) $(dist_pm_DATA)

# clean up files left behind by test suite
clean-local:
	-rm -rf t/target t/stow

# this is more explicit and reliable than the config file trick
edit = sed -e 's|[@]PERL[@]|$(PERL)|g' \
	   -e 's|[@]VERSION[@]|$(VERSION)|g'

bin/stow: bin/stow.in Makefile
	$(edit) < $< > $@
	chmod +x $@

bin/chkstow: bin/chkstow.in Makefile
	$(edit) < $< > $@
	chmod +x $@

lib/Stow.pm: lib/Stow.pm.in Makefile $(DEFAULT_IGNORE_LIST)
	( $(edit) < $<; cat $(DEFAULT_IGNORE_LIST) ) > $@

# The rules for manual.html and manual.texi are only used by
# the developer
doc/manual.html: doc/manual.texi
	-rm -f $@
	texi2html -expandinfo -menu -monolithic -verbose $<

doc/manual.texi: doc/stow.texi
	-rm -f $@
	cp $< $@

doc/stow.8: bin/stow Makefile
	pod2man $< > $@

MODULES = lib/Stow.pm lib/Stow/Util.pm

test: bin/stow bin/chkstow $(MODULES)
	perl -MTest::Harness -Ilib -It -Ibin -e 'runtests(@ARGV)' t/*.t
