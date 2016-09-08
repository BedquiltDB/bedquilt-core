# Installation

## Prerequisites

To use BedquiltDB, you will need the following:

- A PostgreSQL database server, at least version 9.4
- The `pgcrypto` extension, which is usually included with PostgreSQL
- The `plpython3u` extension, which can usually be installed from your package manager


## Installation

Download the latest release from [pgxn](http://pgxn.org/dist/bedquilt/), unzip it, then run the install task to install to the local PostgreSQL installation:
```
$ sudo make install
```

You may need to install the postgres server-dev packages in order for this to work.
On ubuntu, install the `postgresql-server-dev-<VERSION>` package.

Alternatively, you can build a docker image containing a PostgreSQL server with BedquiltDB pre-installed, using our [example Dockerfile](http://github.com/BedquiltDB/docker-bedquiltdb-example).

If you have any trouble with installing BedquiltDB, please do [open an issue](https://github.com/BedquiltDB/bedquilt-core/issues), or ask for help in our [Gitter chat channel](https://gitter.im/BedquiltDB/bedquilt-core).

## Enable the extension

Once the extension is installed on the server, it needs to be enabled on the
database you intend to use:
```
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS plpython3u;
CREATE EXTENSION bedquilt;
```

The various functions that make up `bedquilt` should be available
on the database, and you are ready to connect a client driver.

You can run a simple test with this query:

```sql
select bq_find('test', '{}');
```

If the query doesn't crash, then `bedquilt-core` is installed and ready to use.


## Next steps

Now you can install a client library
(such as [pybedquilt](http://pybedquilt.readthedocs.org)), read the [BedquiltDB Guide](index.md) and start using BedquiltDB.
