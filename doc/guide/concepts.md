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

To use BedquiltDB, the programmer will need to import a BedquiltDB driver for their favourite programming language
and use it to connect to the PostgreSQL/BedquiltDB server. Example, with the [pybedquilt](pybedquilt.readthedocs.org) driver:

```python
import pybdequilt
db = pybedquilt.BedquiltClient('dbname=test')
```

The `db` object holds a connection to the server, and provides an api for the collections in the BedquiltDB database.


## Collections

In a BedquiltDB database, JSON data is stored in collections. You write data into collections,
then read it back out later, like so:

```python
# create a collection called 'users'
db.create_collection('users')

# get a Collection object, referencing the new 'users' collection
users = db['users']

# How many users do you think we have?
print users.count()
```


## Documents

Collections contain documents. A document is essentially a single JSON object.
The BedquiltDB driver handles converting from native data-structures to JSON and back again.
A document can have practically any structure you could want, as long as it's valid JSON,
with one exception: all documents must have an `_id` field, with a string value.

If a document without an `_id` field is written to a collection, then a random string will be
generated and set as the `_id` value. The `_id` field is used as the unique primary-key in
the collection. If two documents are saved with the same `_id`, then the second one will over-write the first.

Here we see an example of saving a python dictionary to a BedquiltDB collection as a
JSON object:

```python
users.insert({
    "_id": "john@example.com",
    "name": "John",
    "age": 45,
    "address": {
        "street": "Elm Row",
        "city": "Edinburgh"
    }
})
```

We can read that same document out later:
```python
john = users.find_one_by_id("john@example.com")
```

Or retrieve it as part of a more general query:
```
edinburgh_users = users.find({"address": {"city": "Edinburgh"}})
```

## Writing Data

There are two operations which write JSON data to a collection: `insert` and `save`.
The `insert` operation takes a JSON document and inserts it into the collection, generating
an `_id` value if needed. Regardless, the `insert` operation always returns the `_id` of the
inserted document:
```python
print pets.insert({"name": "Snuffles", "species": "dog"})
# => "ba40513444b760b7eb2684d8"

print pets.insert({"_id": "some_meaningful_identifier", "name": "Larry", "species": "cat"})
# => "some_meaningful_identifier"
```

The `save` operation also takes a JSON document, but it first
checks if the document has an `_id` field. If it does, and a document with that same `_id`
exists in the collection, then the old document will be overwritten by the new one.
Otherwise, `save` behaves the same as `insert`: if there are no documents in the collection
with the same `_id` then the document is simply inserted into the collection, and the
`_id` returned to the caller:
```python
john = users.find_one_by_id('john@example.com')
john['age'] = 46
result = users.save(john)
print result
# => "john@example.com"
```


## Reading Data


## Updating Data
