MAINTAINERCLEANFILES = Makefile.in

if ENABLE_DOC
SUBDIRS = nonpersistent
endif
DIST_SUBDIRS = nonpersistent

dist_doc_DATA = README
dist_noinst_DATA = doxygen-footer.html *.gif

if ENABLE_API_DOC

apidoc_DATA=api.out/html/*


api.out/html/*: \
		$(EXTRA_DIST) \
		../src/*.h \
		*.gif
	-rm -fr api.out
	$(DOXYGEN) doxygen.conf
	cp *.gif api.out/html

endif

clean-local:
	-rm -fr api.out
