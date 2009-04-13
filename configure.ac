dnl Process this file with Autoconf to produce configure dnl

AC_INIT([stow], [2.0.2], [bug-stow@gnu.org])
AC_PREREQ([2.61])
AM_INIT_AUTOMAKE([-Wall -Werror])
AC_PROG_INSTALL

dnl Check for perl on our system 
dnl call to AC_SUBST(PERL) is implicit
AC_PATH_PROGS([PERL], [perl] [perl5], [false])
if test "x$PERL" = xfalse
then
  AC_MSG_WARN([WARNING: Perl not found; you must edit line 1 of 'stow'])
fi

AC_CONFIG_FILES([Makefile])
AC_OUTPUT
