# General Concepts

This document attempts to describe BedquiltDB at a high level.

## BedquiltDB Architecture

BedquiltDB is divided into two components:

- The `bedquilt` extension for PostgreSQL
- A set of client "driver" libraries

Once the `bedquilt` extension is installed on a PostgreSQL server, a driver library can be connected to the server and used to read and write JSON data. The driver proivides
an API that feels native to the language it is written in and manages
conversion from language-native data structures to JSON and back again.

The following diagram illustrates how a web application written in python might use
the `pybedquilt` driver to interface with a database which has `bedquilt` installed:


![BedquiltDB Architecture](/images/bedquilt_architecture.png)


As we can see from the diagram, the drivers `find` method is really a thin wrapper
around an SQL statement which uses a SQL function called `bq_find`, which is provided
by the `bedquilt` extension. All of the functionality of BedquiltDB is
implemented in this way, with all the "smart stuff" implemented inside the database,
behind custom SQL functions.

This approach provides several advantages over simply writing wrapper logic around
SQL in a specific language:

- The logic of BedquiltDB is performed inside the database, close to the data
- Driver libraries become very simple to implement and test


## Drivers


## Collections


## Documents


## Writing Data


## Reading Data


## Updating Data
