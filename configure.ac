dnl Process this file with Autoconf to produce configure dnl

AC_INIT([stow], [2.1.3], [bug-stow@gnu.org])
AC_PREREQ([2.61])
AC_CONFIG_AUX_DIR([automake])
# Unfortunately we have to disable warnings for overrides, because we
# need to override the built-in `check' rule and also the TEXI2DVI
# variable.
AM_INIT_AUTOMAKE([-Wall -Werror -Wno-override dist-bzip2])
AC_PROG_INSTALL

dnl Check for perl on our system.
dnl Call to AC_SUBST(PERL) is implicit
AC_PATH_PROGS([PERL], [perl] [perl5], [false])
if test "x$PERL" = xfalse
then
  AC_MSG_ERROR([Perl not found; check your \$PATH.])
fi

missing_test_deps=
for mod in Test::More Test::Output; do
  AC_MSG_CHECKING([$mod])
  if $PERL -M$mod -e 1 2>/dev/null
  then
    AC_MSG_RESULT([yes])
  else
    AC_MSG_RESULT([no])
    missing_test_deps="$missing_test_deps $mod"
  fi
done

# N.B. ${var#pattern} will not work with some shells, such as
# Solaris 10's /bin/sh :-(
#
#   http://www.gnu.org/software/autoconf/manual/autoconf.html#Portable-Shell
#
#   eval `$PERL -V:siteprefix -V:installsitelib`
#   pmdir_relative_path="${installsitelib#$siteprefix/}"
#
# This will work:
#
#   pmdir_relative_path=`echo "${installsitelib}" | sed -e "s!^$siteprefix/!!"`
#
# but this is cleaner:
pmdir_relative_path=`\
  $PERL -MConfig \
        -wle '($_ = $Config{installsitelib})
              =~ s!^\Q$Config{siteprefix}/!!; \
              print'`

AC_ARG_WITH(
    [pmdir],
    AS_HELP_STRING(
      [--with-pmdir=DIR],
      [Install Perl modules in DIR]),
    [PMDIR=${withval}],
    [PMDIR='${prefix}'/"$pmdir_relative_path"])
AC_CONFIG_COMMANDS_POST([[
  eval pmdir="$PMDIR"
  cat <<EOF

# Perl modules will be installed to $PMDIR
EOF
  if [ "$pmdir" != "$PMDIR" ]; then
    cat <<EOF
# which will expand to
#
#   $pmdir
#
# unless you override the value of prefix at make-time.
EOF
    echo
  fi

  if test -n "$missing_test_deps"; then
    cat <<EOF >&2
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
! WARNING!  $PERL was missing modules:
!
!   $missing_test_deps
!
! The test suite will fail.  'make install' may still render
! a working installation, but this cannot be guaranteed.
!
! Please (re-)read INSTALL, then install the missing modules
! and try again.
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! 

EOF
  fi
]])
AC_SUBST([PMDIR])

AC_CONFIG_FILES([Makefile])
AC_OUTPUT
