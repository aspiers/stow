## Process this file with Automake to produce Makefile.in

AUTOMAKE_OPTIONS = dist-shar

bin_SCRIPTS = stow
info_TEXINFOS = stow.texi

CLEANFILES = stow manual.html manual.texi

# The rules for manual.html and manual.texi are only used by
# the developer
manual.html: manual.texi
	-rm -f $@
	texi2html -expandinfo -menu -monolithic -verbose $<

manual.texi: stow.texi
	-rm -f $@
	cp $< $@
