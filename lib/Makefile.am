# Copyright (c) 2016-2017 Dridi Boukelmoune
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

AM_CPPFLAGS = \
	-I$(top_srcdir)/inc \
	-I$(top_builddir)/inc \
	-I$(top_builddir)/gen

lib_LTLIBRARIES = libhpack.la

if HAVE_LD_VERSION_SCRIPT
libhpack_la_LDFLAGS = -Wl,--version-script=$(srcdir)/$(PACKAGE).map
else
libhpack_la_LDFLAGS = -export-symbols-regex '^hpack_'
endif

libhpack_la_LDFLAGS += -version-info 0:0:0

libhpack_la_DEPENDENCIES = $(PACKAGE).map

libhpack_la_SOURCES = \
	hpack.c \
	hpack_ctx.c \
	hpack_dec.c \
	hpack_enc.c \
	hpack_huf.c \
	hpack_int.c \
	hpack_tbl.c \
	hpack_val.c \
	$(top_builddir)/inc/hpack.h \
	$(top_builddir)/inc/tbl/hpack_pseudo_headers.h \
	$(top_builddir)/inc/tbl/hpack_static.h \
	$(top_builddir)/inc/tbl/hpack_tbl.h \
	$(top_builddir)/gen/hpack_huf_dec.h \
	$(top_builddir)/gen/hpack_huf_enc.h \
	$(top_builddir)/gen/hpack_static_hdr.h

pkgconfigdir = $(libdir)/pkgconfig
pkgconfig_DATA = $(PACKAGE).pc

noinst_PROGRAMS = hpiencode

hpiencode_LDADD = \
	hpack_ctx.$(OBJEXT) \
	hpack_enc.$(OBJEXT) \
	hpack_int.$(OBJEXT)

EXTRA_DIST = \
	$(PACKAGE).pc.in \
	$(PACKAGE).map
