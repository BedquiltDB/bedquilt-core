# Getting Started


## Prerequisites

To use BedquiltDB, you will need the following:

- A PostgreSQL database server, at least version 9.4
- The `pgcrypto` extension, which is usually included with PostgreSQL


## Installation

First, clone the `bedquilt-core` git repository, and `cd` into it's directory:
```
$ git clone git@github.com:BedquiltDB/bedquilt-core.git
$ cd bedquilt-core
```

Then run the install task to install to the local PostgreSQL installation:
```
$ make install
```

Alternatively, you can build a zip file contianing the extension and use that to
install on a PostgreSQL server:
```
$ make dist
```


## Enable the extension

Once the extension is installed on the server, it needs to be enabled on the
database you intend to use:
```
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION bedquilt;
```

Now, the various functions that make up `bedquilt` should be available
on the database, and you are ready to connect a client driver.
