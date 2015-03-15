EXTENSION = $(shell grep -m 1 '"name":' META.json | \
						sed -e 's/[[:space:]]*"name":[[:space:]]*"\([^"]*\)",/\1/')

EXTVERSION = $(shell grep -m 1 '[[:space:]]\{8\}"version":' META.json | \
						sed -e 's/[[:space:]]*"version":[[:space:]]*"\([^"]*\)",\{0,1\}/\1/')

DATA = $(filter-out $(wildcard sql/*--*.sql),$(wildcard sql/*.sql))
DOCS = $(wildcard doc/*.md)
TESTS = $(wildcard test/sql/*.sql)
REGRESS = $(patsubst test/sql/%.sql,%,$(TESTS))
REGRESS_OPTS = --inputdir=test --load-language=plpgsql
PG_CONFIG ?= pg_config
PG91 = $(shell $(PG_CONFIG) --version | grep -qE " 8\.| 9\.0" && echo no || echo yes)

ifeq ($(PG91),yes)
DATA = $(wildcard sql/*--*.sql) sql/$(EXTENSION)--$(EXTVERSION).sql
EXTRA_CLEAN = sql/$(EXTENSION)--$(EXTVERSION).sql
endif

PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)

ifeq ($(PG91),yes)
all: sql/$(EXTENSION)--$(EXTVERSION).sql
sql/$(EXTENSION)--$(EXTVERSION).sql: sql/$(EXTENSION).sql
	cp $< $@
endif

dist:

		git archive --format zip --prefix=$(EXTENSION)-$(EXTVERSION)/ -o $(EXTENSION)-$(EXTVERSION).zip HEAD
