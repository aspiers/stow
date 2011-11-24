dnl Process this file with Autoconf to produce configure dnl

AC_INIT([stow], [2.1.0], [bug-stow@gnu.org])
AC_PREREQ([2.61])
AC_CONFIG_AUX_DIR([automake])
# Unfortunately we have to disable warnings for overrides, because we
# need to override the built-in `check' rule and also the TEXI2DVI
# variable.
AM_INIT_AUTOMAKE([-Wall -Werror -Wno-override dist-bzip2])
AC_PROG_INSTALL

AM_MAINTAINER_MODE([enable])

dnl Check for perl on our system 
dnl call to AC_SUBST(PERL) is implicit
AC_PATH_PROGS([PERL], [perl] [perl5], [false])
if test "x$PERL" = xfalse
then
  AC_MSG_WARN([WARNING: Perl not found; you must edit line 1 of 'stow'])
fi

AC_ARG_WITH(
    pmdir,
    [  --with-pmdir=DIR        perl modules are in DIR [[LIBDIR/perl5]]],
    [PMDIR=${withval}], [PMDIR=${libdir}/perl5]
)

AC_CONFIG_FILES([Makefile])
AC_OUTPUT
