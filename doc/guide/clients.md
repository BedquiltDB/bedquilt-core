# Clients

Programs interact with the BedquiltDB server through client libraries. These libraries wrap the SQL core of BedquiltDB and provide APIs which feel native to the host programming language.

There are three officially supported clients (or drivers):

- [pybedquilt](http://pybedquilt.readthedocs.org) for Python
- [node-bedquilt](http://node-bedquilt.readthedocs.org) for Node.JS
- [clj-bedquilt](http://bedquiltdb.github.io/clj-bedquilt-docs/) for Clojure


The [bedquilt-examples](https://github.com/BedquiltDB/bedquilt-examples) repository contains two example applications, one for Node.JS and one for Python. The example apps demonstrate the basic usage of BedquiltDB in real applications.

## Using Raw SQL

BedquiltDB is implemented as a set of PostgreSQL functions, which the client libraries wrap around. For example, with `pybedquilt`, a piece of code like `articles.find({'draft': True})`, would be translated to SQL code like `select bq_find('articles', '{"draft": true}');`.

If you find there is no pre-existing client library for your favourite language, or for some reason you can't use a client library, it is possible to use BedquiltDB without a client, buy using your favourite PostgreSQL library and ordinary SQL queries. The full api is documented in the [API Docs](../api_docs.md) page.

For an example, if you couldn't use `pybedquilt`, you could use the raw `psycopg2` library to interface with BedquiltDB, like so:

```
import psycopg2
import json

connection = psycopg2.connect('...')
cursor = connection.cursor()
cursor.execute(
    'select bq_find_one(%)',
    (json.dumps({'draft': True}),)
)
result = cursor.fetchall()
```
