# Bedquilt

![Bedquilt](./resources/bedquilt_logo_tile.png)

A JSON store on PostgreSQL.


# Warning

Bedquilt is currently worse-than-alpha quality and should not be used in production,
or anywhere else for that matter. If Bedquilt kills your database, just imagine me
whispering "told you so" and think hard about how you got yourself into this
mess.


# Goals

- Borrow some of the good ideas and positive attributes of json
  object-stores and bring them to PostgreSQL
- Harness the new jsonb functionality of PostgreSQL and wrap it in a nice
programmatic API that is consistent across languages
- Make use of SQL strong-points, such as schema constraints and table joins
- Build a tool which is actually useful for developers


# Examples

This extension provides the core functionality of BedquiltDB, and can be used from ordinary SQL queries,
though it is recommended to use one of the driver libraries for you favourite programming language instead.

```PLpgSQL
-- Insert two documents into the 'people' collection.
select bq_insert(
    'people',
    '{"_id": "sarah@example.com",
      "name": "Sarah",
      "likes": ["icecream", "code"]}'
);
select bq_insert(
    'people',
    '{"name": "Mike",
      "likes": ["code", "rabbits"]}'
);


-- Find a single document,
-- where the "name" field is the string value "Mike".
select bq_find_one(
    'people',
    '{"name":  "Mike"}'
);


-- Find all documents in the 'people' collection
select bq_find('people', '{}');


-- Find all people who like icecream
select bq_find('people', '{"likes": ["icecream"]}');


-- Find a single document by its "_id" field.
-- This query hits the primary key index on the _id field
select bq_find_one_by_id('people', 'sarah@example.com');


-- Create an empty collection
select bq_create_collection('things');


-- Get a list of existing collections
select bq_list_collections();
```


# Prerequisites

- PostgreSQL >= 9.4
- PL/pgSQL
- The pgcrypto extension


# Installation

First, clone this repositroy:

```
$ git clone https://github.com/BedquiltDB/bedquilt-core.git
$ cd bedquilt-core
```

Run the following to build the extension and install it to the local database:

```
$ make install
```

Run this to build to a zip file:

```
$ make dist
```

Then, on the postgres server:

```PLpgSQL
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION bedquilt;
```


# Tests

Run `bin/run-tests.sh` to run the test suite. Requires a `bedquilt_test` database
that the current user owns.


# Documentation

Project documnetation hosted at [Read The Docs](http://bedquiltdb.readthedocs.org).

To build documentation, install the `mkdocs` utility and run:
```
$ make docs
```



# License

Bedquilt is released under the [MIT License](./LICENSE.txt).
