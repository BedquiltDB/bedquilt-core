# Bedquilt-core makefile
VERSION = $(shell cat ./VERSION)


all:
	echo "Nope, not yet"


clean:
	rm -rf dist/packages
	rm -rf .tmp


.tmp:
	mkdir .tmp


dist:
	mkdir dist


dist/sql: dist
	mkdir dist/sql


dist/packages: dist
	mkdir dist/packages


build-sql: dist/sql
	cat src/sql/*.sql > dist/sql/bedquilt--$(VERSION).sql


VERSION=HEAD
build-head:
	$(MAKE) build-sql


install-head:
	$(MAKE) install EXTVERSION="HEAD"


docs:
	python bin/generate_docs.py && mkdocs build --clean


test: install-head
	bin/run-tests.sh


.PHONY: test build-head install-head docs all clean
