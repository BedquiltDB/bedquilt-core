# Bedquilt-core makefile
VERSION = $(shell cat ./VERSION)


all:
	echo "Nope, not yet"


clean:
	rm -rf dist/packages
	rm -rf .tmp


.tmp:
	mkdir .tmp


.tmp/packages: .tmp
	mkdir .tmp/packages


.tmp/packages/bedquilt--$(VERSION): .tmp/packages build-sql
	mkdir -p $@
	mkdir -p $@/sql
	cp dist/sql/*.sql $@/sql/
	sed s/\{\{VERSION\}\}/$(VERSION)/g src/META.json > $@/META.json
	sed s/\{\{VERSION\}\}/$(VERSION)/g src/bedquilt.control > $@/bedquilt.control
	cp src/Makefile $@/
	cp -R doc $@/doc


dist:
	mkdir -p dist


dist/sql: dist
	mkdir -p dist/sql


dist/packages: dist
	mkdir -p dist/packages


build-sql: dist/sql
	cat $(shell ls src/sql/*.sql | sort) > dist/sql/bedquilt--$(VERSION).sql


build-package: .tmp/packages/bedquilt--$(VERSION) dist/packages
	cp -R .tmp/packages/bedquilt--$(VERSION) dist/packages


build-package-head:
	make build-package VERSION=HEAD


build-head:
	make build-sql VERSION=HEAD


install:
	make build-package
	make install -C dist/packages/bedquilt--$(VERSION)


install-head:
	make build-package-head
	make install -C dist/packages/bedquilt--HEAD


docs:
	python bin/generate_docs.py && mkdocs build --clean

docs-serve: docs
	mkdocs serve


test: install-head
	bin/run-tests.sh


.PHONY: test build-head build-package build-package-head install-head install docs docs-serve all clean
