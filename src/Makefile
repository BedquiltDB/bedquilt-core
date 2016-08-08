# PGXN stuff
EXTENSION = $(shell grep -m 1 '"name":' META.json | \
	sed -e 's/[[:space:]]*"name":[[:space:]]*"\([^"]*\)",/\1/')


EXTVERSION = $(shell grep -m 1 '[[:space:]]\{8\}"version":' META.json | \
	sed -e 's/[[:space:]]*"version":[[:space:]]*"\([^"]*\)",\{0,1\}/\1/')


#DATA = $(filter-out $(wildcard sql/*--*.sql),$(wildcard sql/*.sql))
DATA = $(wildcard sql/*--*.sql)
DOCS = $(wildcard doc/*.md)
TESTS = $(wildcard test/sql/*.sql)
REGRESS = $(patsubst test/sql/%.sql,%,$(TESTS))
REGRESS_OPTS = --inputdir=test --load-language=plpgsql
PG_CONFIG ?= pg_config


PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)


dist:
	git archive --format zip --prefix=$(EXTENSION)-$(EXTVERSION)/ -o $(EXTENSION)-$(EXTVERSION).zip HEAD
# /PGXN stuff


install-head:
	make install EXTVERSION="HEAD"


docs:
	python bin/generate_docs.py && mkdocs build --clean


test: install-head
	bin/run-tests.sh


.PHONY: test installdocs
