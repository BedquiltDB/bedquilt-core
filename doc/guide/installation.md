# Installation

## Prerequisites

To use BedquiltDB, you will need the following:

- A PostgreSQL database server, at least version 9.4
- The `pgcrypto` extension, which is usually included with PostgreSQL


## Installation

Download the latest release from [pgxn](http://pgxn.org/dist/bedquilt/), unzip it, then run the install task to install to the local PostgreSQL installation:
```
$ make install
```

You may need to install the postgres server-dev packages in order for this to work.
On ubuntu, install the `postgresql-server-dev-<VERSION>` package.


Alternatively, you can build a docker image containing a PostgreSQL server with BedquiltDB pre-installed, using our [example Dockerfile](http://github.com/BedquiltDB/docker-bedquiltdb-example).


## Enable the extension

Once the extension is installed on the server, it needs to be enabled on the
database you intend to use:
```
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION bedquilt;
```

The various functions that make up `bedquilt` should be available
on the database, and you are ready to connect a client driver.


## Next steps

Now you can install a client library
(such as [pybedquilt](http://pybedquilt.readthedocs.org)), and start using BedquiltDB.
