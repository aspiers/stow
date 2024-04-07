dnl This file is part of GNU Stow.
dnl
dnl GNU Stow is free software: you can redistribute it and/or modify it
dnl under the terms of the GNU General Public License as published by
dnl the Free Software Foundation, either version 3 of the License, or
dnl (at your option) any later version.
dnl
dnl GNU Stow is distributed in the hope that it will be useful, but
dnl WITHOUT ANY WARRANTY; without even the implied warranty of
dnl MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
dnl General Public License for more details.
dnl
dnl You should have received a copy of the GNU General Public License
dnl along with this program. If not, see https://www.gnu.org/licenses/.

dnl Process this file with Autoconf to produce configure dnl

AC_INIT([stow], [2.4.1], [bug-stow@gnu.org])
AC_PREREQ([2.61])
AC_CONFIG_AUX_DIR([automake])
# Unfortunately we have to disable warnings for overrides, because we
# need to override the built-in `check-TESTS' rule and also the TEXI2DVI
# variable.
AM_INIT_AUTOMAKE([-Wall -Werror -Wno-override dist-bzip2 foreign])
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
    if test -n "$STRICT_TESTS"; then
      exit 1
    fi
  fi
]])
AC_SUBST([PMDIR])

AC_CONFIG_FILES([Makefile])
AC_OUTPUT
