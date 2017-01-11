# Copyright (c) 2016 Dridi Boukelmoune
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.

# CASHPACK_SANITY_CHECK
# ---------------------
AC_DEFUN([CASHPACK_SANITY_CHECK], [

	dnl hexcheck
	AC_MSG_CHECKING([for RFC 7541-compatible hexdumps])

	if ! "$srcdir"/tst/hexcheck 2>/dev/null
	then
		AC_MSG_RESULT([no])
		"$srcdir"/tst/hexcheck
		AC_MSG_FAILURE([hexdumps fail sanity check])
	fi

	AC_MSG_RESULT([yes])

	dnl bincheck
	AC_MSG_CHECKING([for working bindumps to hexdumps conversions])

	if ! "$srcdir"/tst/bincheck 2>/dev/null
	then
		AC_MSG_RESULT([no])
		"$srcdir"/tst/bincheck
		AC_MSG_FAILURE([bindumps fail sanity check])
	fi

	AC_MSG_RESULT([yes])

	dnl Mutual exclusivity of additional checkers
	cashpack_options="$(
		echo "$with_memcheck$with_asan$with_msan$with_ubsan$with_lcov" |
		awk -F yes '{print NF - 1}'
	)"

	test "$cashpack_options" -gt 1 &&
	AC_MSG_FAILURE([Valgrind, ASAN, MSAN, UBSAN and lcov support can't be combined])

])

# _CASHPACK_CHECK_FLAG
----------------------
AC_DEFUN([_CASHPACK_CHECK_FLAG], [

         AX_CHECK_COMPILE_FLAG([$1],
		 [CASHPACK_CFLAGS="$CASHPACK_CFLAGS $1"],
		 [],
		 [$CASHPACK_CFLAGS $CFLAGS])

])

# _CASHPACK_CHECK_FLAGS
-----------------------
AC_DEFUN([_CASHPACK_CHECK_FLAGS], [

	m4_foreach([_flag],
		m4_split(m4_normalize([$1])),
			[_CASHPACK_CHECK_FLAG(_flag)])

])

# CASHPACK_CHECK_FLAGS
----------------------
AC_DEFUN([CASHPACK_CHECK_FLAGS], [

	CASHPACK_CFLAGS=

	dnl Standards compliance
	_CASHPACK_CHECK_FLAGS([
		-pedantic
		-std=c99
		-D_POSIX_C_SOURCE=200809L
	])

	dnl This corresponds to FreeBSD's WARNS level 6
	_CASHPACK_CHECK_FLAGS([
		-Werror
		-Wall
		-Wno-format-y2k
		-Wstrict-prototypes
		-Wmissing-prototypes
		-Wpointer-arith
		-Wreturn-type
		-Wcast-qual
		-Wswitch
		-Wshadow
		-Wunused-parameter
		-Wcast-align
		-Wchar-subscripts
		-Wnested-externs
		-Wextra
		-Wno-sign-compare
	])

	dnl Can't follow FreeBSD too closely
	_CASHPACK_CHECK_FLAGS([
		-Wno-error=cast-qual
		-Wno-error=discarded-qualifiers
		-Wno-error=ignored-qualifiers
		-Wno-error=incompatible-pointer-types-discards-qualifiers
		-Wno-error=write-strings
	])

	dnl Other desirable warnings
	_CASHPACK_CHECK_FLAGS([
		-Wmissing-variable-declarations
		-Wredundant-decls
		-Wsign-compare
		-Wunused-result
	])

	dnl SunCC-specific warnings
	_CASHPACK_CHECK_FLAGS([
		[-Wc,-errwarn=%all]
		[-Wc,-errtags=yes]
	])

	CFLAGS="$CASHPACK_CFLAGS $CFLAGS"

])

# CASHPACK_CHECK_GOLANG
-----------------------
AC_DEFUN([CASHPACK_CHECK_GOLANG], [

	AC_MSG_CHECKING([for golang >= 1.7])

	[golang_version="$(
		go version 2>/dev/null |
		tr ' ' '\n' |
		grep '^go[1-9]' |
		sed s/go//
	)"]

	AS_VERSION_COMPARE([$golang_version], [1.7],
		[golang_17=no],
		[golang_17=yes],
		[golang_17=yes])

	AC_MSG_RESULT([$golang_17])
	AM_CONDITIONAL([HAVE_GOLANG], [test "$golang_17" = yes])

	if test "$golang_17" = yes
	then
		GOROOT="$(go env GOROOT)"
		AC_SUBST([GOROOT])
	fi

	dnl Define an automake silent execution for go
	[am__v_GO_0='@echo "  GO      " $''@;']
	[am__v_GO_1='']
	[am__v_GO_='$(am__v_GO_$(AM_DEFAULT_VERBOSITY))']
	[AM_V_GO='$(am__v_GO_$(V))']
	AC_SUBST([am__v_GO_0])
	AC_SUBST([am__v_GO_1])
	AC_SUBST([am__v_GO_])
	AC_SUBST([AM_V_GO])

])

# CASHPACK_PROG_HEXDUMP
-----------------------
AC_DEFUN([CASHPACK_PROG_HEXDUMP], [

	AC_CHECK_PROGS(HEXDUMP, [hexdump], [no])
	AM_CONDITIONAL([HAVE_HEXDUMP], [test "$HEXDUMP" != no])

])

# CASHPACK_PROG_RST2MAN
-----------------------
AC_DEFUN([CASHPACK_PROG_RST2MAN], [

	AC_CHECK_PROGS(RST2MAN, [rst2man.py rst2man], [true])
	AC_SUBST([RST2MAN])

])

# CASHPACK_PROG_UNCRUSTIFY
# ------------------------
AC_DEFUN([CASHPACK_PROG_UNCRUSTIFY], [

	UNCRUSTIFY_OPTS="-c '\$(srcdir)/uncrustify.cfg' -q -l C --no-backup"

	AC_CHECK_PROGS(UNCRUSTIFY, [uncrustify], [true])
	test "$UNCRUSTIFY" = true && UNCRUSTIFY_OPTS=

	AC_SUBST([UNCRUSTIFY])
	AC_SUBST([UNCRUSTIFY_OPTS])

])

# CASHPACK_LIB_NGHTTP2
# --------------------
AC_DEFUN([CASHPACK_LIB_NGHTTP2], [

	PKG_CHECK_MODULES([NGHTTP2],
		[libnghttp2],
		[NGHTTP2=yes],
		[NGHTTP2=no])

	AC_SUBST([NGHTTP2])
	AM_CONDITIONAL([HAVE_NGHTTP2], [test "$NGHTTP2" = yes])

])

# CASHPACK_WITH_MEMCHECK
# ----------------------
AC_DEFUN([CASHPACK_WITH_MEMCHECK], [

	AC_CHECK_PROGS(VALGRIND, [valgrind], [no])

	AC_ARG_WITH([memcheck],
		AS_HELP_STRING(
			[--with-memcheck],
			[Run the test suite with Valgrind]),
		[MEMCHECK="$withval"],
		[MEMCHECK=no])

	test "$MEMCHECK" = yes -a "$VALGRIND" = no &&
	AC_MSG_FAILURE([Valgrind is required with memcheck])

	AC_SUBST([MEMCHECK])

])

# _CASHPACK_ASAN
# --------------
AC_DEFUN([_CASHPACK_ASAN], [

	CFLAGS="$CFLAGS -fsanitize=address"
	AC_CHECK_LIB(
		[asan],
		[__asan_address_is_poisoned],
		[LIBS="$ac_check_lib_save_LIBS"])

])

# CASHPACK_WITH_ASAN
# ------------------
AC_DEFUN([CASHPACK_WITH_ASAN], [

	AC_ARG_WITH([asan],
		AS_HELP_STRING(
			[--with-asan],
			[Build binaries with address sanitizer]),
		[_CASHPACK_ASAN],
		[])

])

# CASHPACK_WITH_MSAN
# ------------------
AC_DEFUN([CASHPACK_WITH_MSAN], [

	AC_ARG_WITH([msan],
		AS_HELP_STRING(
			[--with-msan],
			[Build binaries with address sanitizer]),
		[CFLAGS="$CFLAGS -fsanitize=memory -fsanitize-memory-track-origins"],
		[])

])

# _CASHPACK_UBSAN
# ---------------
AC_DEFUN([_CASHPACK_UBSAN], [

	CFLAGS="$CFLAGS -fsanitize=undefined"
	AC_CHECK_LIB([ubsan],
		[__ubsan_handle_add_overflow],
		[LIBS="$ac_check_lib_save_LIBS"])

])

# CASHPACK_WITH_UBSAN
# -------------------
AC_DEFUN([CASHPACK_WITH_UBSAN], [

	AC_ARG_WITH([ubsan],
		AS_HELP_STRING(
			[--with-ubsan],
			[Build binaries with undefined sanitizer]),
		[_CASHPACK_UBSAN],
		[])

])

# _CASHPACK_LCOV
# --------------
AC_DEFUN([_CASHPACK_LCOV], [

	AC_CHECK_PROGS(LCOV, [lcov], [no])
	test "$LCOV" = no &&
	AC_MSG_FAILURE([Lcov is required for code coverage])

	AC_CHECK_PROGS(GENHTML, [genhtml], [no])
	test "$GENHTML" = no &&
	AC_MSG_FAILURE([Lcov is missing genhtml for reports generation])

	LCOV_RULES="

lcov: all
	@\$(LCOV) -z -d .
	@\$(MAKE) \$(AM_MAKEFLAGS) -k check
	@\$(LCOV) -c -o tst.info -d tst
	@\$(LCOV) -c -o lib.info -d lib
	@\$(LCOV) -a tst.info -a lib.info -o raw.info
	@\$(LCOV) -r raw.info '/usr/*' -o cashpack.info
	@\$(GENHTML) -o lcov cashpack.info
	@echo file://\$(abs_builddir)/lcov/index.html

clean: lcov-clean

lcov-clean:
	@find \$(abs_builddir) -depth '(' \
		-name '*.gcda' -o \
		-name '*.gcov' -o \
		-name '*.gcno' -o \
		-name '*.info' \
		')' -delete
	@rm -rf \$(abs_builddir)/lcov/

.PHONY: lcov lcov-clean

"

	CPPFLAGS="$CPPFLAGS -DNDEBUG"
	CFLAGS="$CFLAGS -O0 -g -fprofile-arcs -ftest-coverage"
	LDFLAGS="$LDFLAGS -lgcov"

	if lcov --help | grep -q -e --config-file
	then
		LCOV_OPTS="--config-file \$(srcdir)/lcovrc"
		LCOV="$LCOV $LCOV_OPTS"
		GENHTML="$GENHTML $LCOV_OPTS"
	fi

	AC_SUBST([LCOV])
	AC_SUBST([GENHTML])
	AC_SUBST([LCOV_RULES])
	m4_ifdef([_AM_SUBST_NOTMAKE], [_AM_SUBST_NOTMAKE([LCOV_RULES])])

])

# CASHPACK_WITH_LCOV
# ------------------
AC_DEFUN([CASHPACK_WITH_LCOV], [

	AC_ARG_WITH([lcov],
		AS_HELP_STRING(
			[--with-lcov],
			[Measure test suite code coverage with lcov]),
		[_CASHPACK_LCOV],
		[])

])

# CASHPACK_ENABLE_DOCS
# --------------------
AC_DEFUN([CASHPACK_ENABLE_DOCS], [

	AC_ARG_ENABLE([docs],
		AS_HELP_STRING(
			[--enable-docs],
			[Man pages can be omitted if built from a dist archive]))

	AM_CONDITIONAL([DOCS], [test "$enable_docs" != "no"])
])
