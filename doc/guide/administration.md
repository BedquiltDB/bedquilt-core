# Administration

BedquiltDB is built on top of [PostgreSQL](https://postgresql.org), so administering a BedquiltDB installation means administering the PostgreSQL server, plus the BedquiltDB extension.

Realistically, anyone deploying BedquiltDB should be familiar with the care and feeding of PostgreSQL.


## Requirements

The BedquiltDB extension has the following requirements:

- PostgreSQL >= 9.5
- PL/PgSQL
- PL/Python3u
- PgCrypto


## Enabling the Extension:

Simply:

```
create extension if not exists pgcrypto;
create extension if not exists plpython3u;
create extension bedquilt;
```


## How BedquiltDB Works

The BedquiltDB extension is a collection of userd-defined-functions, each beginning with the prefix `bq_`. Examples include `bq_find`, `bq_save`, and `bq_util_generate_id`. For a full list of BedquiltDB functions, see the complete [API Docs](../api_docs.md).

When write operations are performed, for example by calling `bq_insert`, BedquiltDB creates a table in the database, corresponding to the logical `collection` that the documents were written to.

The tables created by BedquiltDB have a consistent layout, consisting of the following columns:


Column Name   | Type
--------------|--------------
\_id          | varchar(256)
bq_jdoc       | jsonb
created       | timestamptz
updated       | timestamptz


BedquiltDB creates a unique index on the `_id` column, a GIN index on the `bq_jdoc` column, and adds a uniqueness constraint on `bq_jdoc->>'id'`.

In ordinary operation, clients will connect to the PostgreSQL database via a SQL/PostgreSQL library, and call the various `bq_*` functions and everything should Just Work™.


## Dynamic Creation of Collections/Tables


BedquiltDB mimics other NoSQL stores such as MongoDB, by transparently creating a collection (which are just PostgreSQL tables) when a document is first written to that collection. For example, the following Python code will first check if a `widgets` table exists, and then create that table if necessary, before proceeding to insert a row into the `widgets` table:

```python
widgets = db['widgets']
widgets.insert({'_id': 'abcd', 'name': 'spanner'})
```

Collections can be created explicitely, ahead of time, with the `bq_create_collection` function.


## Users and Permissions

The PostgreSQL user account which is connected should have been granted permissions to do whatever it needs to do on that PostgreSQL database.

Really, this is up to the database operators and application developers to decide. If the BedquiltDB client should be able to create collections dynamically, then the appropriate permissions (for creating tables) should be granted to that user. If the client should be able to insert and remove data, the same applies. In many ways, BedquiltDB is designed with a full-permissions user account in mind, but in the case where a client tries to perform an action which they do not have permissions for, an ordinary PostgreSQL permission error will be raised.

If you want a client to only be able to read data, but not insert or create collections, just set the permissions and it will all work fine.

See the PostgreSQL documentation on [User Management](https://www.postgresql.org/docs/current/static/user-manag.html) and the [GRANT Command](https://www.postgresql.org/docs/current/static/sql-grant.html).
