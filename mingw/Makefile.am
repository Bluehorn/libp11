AUTOMAKE_OPTIONS = foreign 1.10

MAINTAINERCLEANFILES = \
	Makefile.in config.h.in config.h.in~ configure \
	install-sh ltmain.sh missing mkinstalldirs \
	compile depcomp config.log config.status \
	config.guess config.sub acinclude.m4 aclocal.m4 \
	config.log configure packaged
EXTRA_DIST = svnignore

dist_noinst_DATA = COPYING bootstrap examples/Makefile examples/*.c examples/README
dist_doc_DATA = NEWS

SUBDIRS = src doc

# Allow detection of packaged tarball
dist-hook:
	echo > "$(distdir)/packaged"
