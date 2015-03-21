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


# Prerequisites

- PostgreSQL >= 9.4
- PL/pgSQL
- The pgcrypto extension


# Installation

Run the following to build the extension and install it to the local database:

```bash

make install

```

Run this to build to a zip file:

```bash

make dist

```

Then, on the postgres server:

```sql

CREATE EXTENSION bedquilt;

```


# Tests

Run `bin/run-tests.sh` to run the test suite. Requires a `bedquilt_test` database
that the current user owns.


# License

Bedquilt is released under the [MIT License](./LICENSE.txt).
