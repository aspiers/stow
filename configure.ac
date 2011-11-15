dnl Process this file with Autoconf to produce configure

AC_INIT(stow.in)

PACKAGE=stow
VERSION=1.4.0
AM_INIT_AUTOMAKE(stow, $VERSION)
AC_SUBST(PACKAGE)
AC_SUBST(VERSION)

AM_MAINTAINER_MODE([enable])

AC_ARG_PROGRAM

AC_PROG_INSTALL

AC_PATH_PROGS(PERL, perl perl5, false)

if test "x$PERL" = xfalse
then
  echo 'WARNING: Perl not found; you must edit line 1 of `stow'"'"
fi

dnl FIXME: haven't figured out how to use this yet.  See `Installation
dnl Directory Variables' section of autoconf manual.  Looks like we
dnl can't do a standard AC_SUBST(PMDIR) because installation directory
dnl variables are kept unexpanded, so
dnl
dnl       use lib "@PMDIR@";
dnl
dnl would end up as:
dnl
dnl       use lib "${exec_prefix}/lib/perl5";
dnl
dnl Instead it suggests that the substition should be done in the
dnl Makefile, but I haven't figured out how to do that yet.  As
dnl stow.in already contains @PERL@, presumably either we'd have to
dnl stop config.status performing that substitution and then handle
dnl both substitutions in the same way, or have a two-phase approach,
dnl i.e. stow.in.in -> stow.in -> stow, which ostensibly sucks.
dnl
dnl AC_ARG_WITH(
dnl     pmdir,
dnl     [  --with-pmdir=DIR        perl modules are in DIR [[LIBDIR/perl5]]],
dnl     [PMDIR=${withval}], [PMDIR=${libdir}/perl5]
dnl )

AC_OUTPUT(Makefile stow, chmod +x stow)
