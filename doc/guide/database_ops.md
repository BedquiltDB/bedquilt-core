# Database Operations

There are four operations in BedquiltDB which work at the Database level, they are `create_collection`, `delete_collection`, `list_collections` and `collection_exists`. Example code below is written in python, using the `pybedquilt` driver.


## create_collection

Creates a new collection with a given name, if the collection does not already exist. Returns a Boolean value, `true` if the collection was created, `false` if the collection already existed.

Behind the scenes, the collection takes the form of a PostgreSQL Table, with the JSON documents being stored in a `jsonb` column called `bq_jdoc`.

```
db.create_collection(name::String) => Boolean
```

Example:
```python
db = BedquiltClient('dbname=test')
was_created = db.create_collection('users')
if was_created:
    print "user collection did not exsit before, but it does now."
```


## delete_collection

Deletes a collection with a given name, if the collection exists. All data in the collection is destroyed instantly. There is no way to recover deleted data. Returns a Boolean value, `true` if the collection was destroyed, `false` if the collection did not exist.

On the PostgreSQL server, the table corresponding to this collection is dropped.

```
db.delete_collection(name::String) => Boolean
```

Example:
```python
db = BedquiltClient('dbname=test')
was_deleted = db.delete_collection('users')
if was_deleted:
    print "user collection used to exist, now it is gone."
```


## list_collections

Produces a (possibly empty) list of all the collection names in this BedquiltDB instance.

Behind the scenes, this operation looks in PostgreSQL for the names of all tables which it knows where created by the `bedquilt` system.

```
db.list_collections() => List[String]
```

Example:
```python
db = BedquiltClient('dbname=test')
print db.list_collections()
# => ['users', 'notes', 'notebooks', 'files', 'audit_log']
```


## collection_exists

Checks if the named collection exists on the server, returning `true` if it does, `false` otherwise.

```
db.collection_exists(name::String) => Boolean
```

Example:
```python
db = BedquiltClient('dbname=test')
print db.collection_exists('users')
# => True
```
