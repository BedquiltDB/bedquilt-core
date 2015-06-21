# Bedquilt-core makefile
VERSION = $(shell cat ./VERSION)


install-head:
	make install EXTVERSION="HEAD"


docs:
	python bin/generate_docs.py && mkdocs build --clean


test: install-head
	bin/run-tests.sh


.PHONY: test install-head docs
