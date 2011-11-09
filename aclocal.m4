dnl This definition comes from automake 1.0

AC_DEFUN(fp_PROG_INSTALL,
[AC_PROG_INSTALL
test -z "$INSTALL_SCRIPT" && INSTALL_SCRIPT='${INSTALL} -m 755'
AC_SUBST(INSTALL_SCRIPT)dnl
])
