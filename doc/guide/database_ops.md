# Database Operations

There are four operations in BedquiltDB which work at the Database level, they are `create_collection`, `delete_collection`, `list_collections` and `collection_exists`. Example code below is written in python, using the `pybedquilt` driver.


## `create_collection`

Creates a new collection with a given name, if the collection does not already exist. Returns a Boolean value, `true` if the collection was created, `false` if the collection already existed.

```
db.create_collection(name::String) => Boolean
```

Example:
```python
client = BedquiltClient('dbname=test')
was_created = client.create_collection('users')
if was_created:
    print "user collection did not exsit before, but it does now."
```

## `delete_collection`



## `list_collections`



## `collection_exists`
