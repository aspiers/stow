## Process this file with Automake to produce Makefile.in

bin_SCRIPTS = stow chkstow
info_TEXINFOS = stow.texi
dist_man_MANS = stow.8
dist_doc_DATA = README

TESTS_ENVIRONMENT=$(PERL) -I $(top_srcdir)
TESTS = \
	t/cleanup_invalid_links.t  \
	t/defer.t                  \
	t/examples.t               \
	t/find_stowed_path.t       \
	t/foldable.t               \
	t/join_paths.t             \
	t/parent.t                 \
	t/stow_contents.t          \
	t/stow.t                   \
	t/unstow_contents_orig.t   \
	t/unstow_contents.t 	   \
	t/chkstow.t

AUTOMAKE_OPTIONS = dist-shar
EXTRA_DIST = $(TESTS) t/util.pm stow.in
CLEANFILES = $(bin_SCRIPTS)

# clean up files left behind by test suite
clean-local:
	-rm -rf t/target t/stow

# this is more explicit and reliable than the config file trick
edit = sed -e 's|[@]PERL[@]|$(PERL)|g' \
	   -e 's|[@]PACKAGE[@]|$(PACKAGE)|g' \
	   -e 's|[@]VERSION[@]|$(VERSION)|g'

stow: stow.in Makefile
	$(edit) < $< > $@
	chmod +x $@

chkstow: chkstow.in Makefile
	$(edit) < $< > $@
	chmod +x $@

# The rules for manual.html and manual.texi are only used by
# the developer
manual.html: manual.texi
	-rm -f $@
	texi2html -expandinfo -menu -monolithic -verbose $<

manual.texi: stow.texi
	-rm -f $@
	cp $< $@

test: stow chkstow
	perl -MTest::Harness -e 'runtests(@ARGV)' t/*.t
