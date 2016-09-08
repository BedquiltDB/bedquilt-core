# BedquiltDB Spec


## Overview

This document specifies a high-level interface to BedquiltDB.
The examples will be given in a pseudo-python language.


## Connections

- Connect to a PostgreSQL database directly:
`db = bedquilt.BedquiltClient("localhost/bedquilt_test")`
- Get a collection from the database:
`coll = db[‘people’]`


## Database Operations

## Create Collection

Create a collection. Does nothing if the collection already exists.

Params:
- collectionName::String

Returns: Boolean indicating whether the collection was created.

Examples:
```
db.create_collection("people")
```


## Delete Collection

Delete a collection. Does nothing if the collection does not exist.

Params:
- collectionName::String

Returns: Boolean indicating whether the collection was deleted.

Examples:
```
db.delete_collection("people")
```


## List Collections

Get a list of collection names.

Params: None

Returns: List of string names of collections.

Examples:
```
for collection_name in db.list_collections():
    print collection_name
```


## Collection Operations

### Create Index:

Add an index to the collection.  The spec is a json-like map where the
keys are field names and the values are numbers. positive numbers
correspond to ascending index, negative numbers to descending
index. If unique is true, then the index will enforce uniqueness.

Params:
- spec::Map
- unique::Boolean (default False)

Returns: None

Examples:
```
coll.create_index({"name": 1})
```

### Delete Index

Remove an index from the collection.

Params:
- spec::Map

Returns: None

Examples:
```
coll.delete_index({"name": 1})
```

### Add Constraint

Adds a constraint to the fields of this collection.  The spec
describes the fields which should be constrained, and how. This will
validate all existing documents in the collection before
applying. Further writes to this collection will be validated before
writing, and will fail if the written document does not satisfy the
constraints.

Spec Options:
- $required (Boolean) : Enforces that this
  field must be present in all documents
- $notnull (Boolean) : Field must never have a null value
- $type (String) : enforce the type of this field,
  options are "string", "number|double|float",  "array", "object"

Params:
- spec::Map

Returns: Boolean indicating success or failure

Examples:
```
coll.add_constraint({"name": {"$required": True,
                              "$notnull": True,
                              "$type": "string",
                              "$unique": False}})
```


### Insert

Insert a document into the collection. If the document does not
contain an \_id field, one will be generated and added to the
document before insertion. If an \_id is supplied and there
already exists a document in this collection with the
same \_id, that is an error.

Params:
- doc::Map

Returns: String representing the \_id field of the document

Examples:
```
_id = coll.insert({"_id": "sarah@example.com",
                   "name": "Sarah Bingham",
                   "age": 42,
                   "likes": ["icecream", "code", "hockey"]})
```


### Save

Write a document to the collection.
If an \_id is supplied and there already exists a document in this
collection with the same \_id, that document will be
replaced with this one.

If the document does not contain an \_id field, one will be
generated and added to the document before insertion as
a new document.

Params:
- doc::Map

Returns: String representing the \_id field of the document

Examples:
```
_id = coll.insert({"_id": "sarah@example.com",
                   "name": "Sarah Bingham",
                   "age": 42,
                   "likes": ["icecream", "code", "hockey"]})
sarah_doc = coll.find_one(_id)
sarah_doc[‘likes’].append("music")
coll.save(sarah_doc)
```


### Find

Retrieve a sequence of documents which match the provided
query document. if `skip` is supplied, that number of documents are skipped.
If `limit` is supplied, the result sequence is limited to that number of documents.
The `sort` parameter is an array of `key->integer` maps, where the key is the
name of the field to sort by and the integer indicates ascending (1) or
descending (-1) ordering. If the sort array contains more than one value, the
sorts are applied in that order. For example `[{age: 1}, {name: 1}]` means
"sort by age, then by name".

Params:
- query::Map
- skip::Integer (optional, default 0)
- limit::Integer (optional, default null)
- sort::Array (optional, default null)

Returns: a (possibly empty) sequence of documents.

Examples:
```
people_who_like_icecream = coll.find(
    {"likes": ["icecream"]}
)

coll.find(
    {"likes": ["icecream"]},
    skip=4,
    limit=2,
    sort=[{"age": 1}]
)

coll.find(
    {"likes": ["icecream"]},
    skip=4,
    limit=2,
    sort=[{"age": 1, "name": -1}]
)
```


### Find One

Retrieve the first document which matches the provided query document
from the collection. The filter specifies the structure of the
returned document.

Params:
- query::Map
- skip::Integer (optional, default 0)
- sort::Array (optional, default null)

Returns: A single document, or null if none could be found.

Examples:
```
likes = coll.find_one({"name": "Sarah Bingham"}, {"likes": 1})
```


### Find One By Id

Retrieve the document whose `_id` field matches the supplied value.

Params:
- id::String

Returns: A single document, or null if none could be found.

Examples:
```
likes = coll.find_one_by_id("sarah@example.com")
```


### Find Many By Ids

Retrieve documents whose `_id` field is in the supplied list of ids.

Params:
- ids::List[String]

Returns: a (possibly empty) sequence of documents.

Examples:
```
orders = coll.find_many_by_ids(["X224", "X573", "X248"])
```


### Aside: Advanced Query Operations

Query documents are normally used as a sub-document match, following the semantics of PostgreSQL `@>` operator. A query document may optionally include _Advanced Query Operators_, which take the form of key=>value mappings where the key begins with a `$` character.

These query operators can be mixed into a query document at any location, and at any level of nesting,
and will be filtered out of the query before execution. In this way a match query can be comibined with advanced query operators.

The following operators are supported:

#### $eq => Any

Asserts that a field value is equal to some specified value.
Examples:
```
collection.find({
    "city": {
        "$eq": "Glasgow"
    }
})
```

#### $noteq => Any

Asserts that a field value is not equal to some specified value.
Examples:

```
collection.find({
    "city": {
        "$noteq": "Edinburgh"
    }
}
```

#### $gt => Number

Asserts that a value is greater than some specified value.
Examples:
```
collection.find({
    "voteCount": {
        "$gt": 40
    }
})
```

#### $gte => Number

Asserts that a value is greater than or equal to some specified value.
Examples:
```
collection.find({
    "voteCount": {
        "$gte": 20
    }
})
```

#### $lt => Number

Asserts that a value is less than some specified value.
Examples:
```
collection.find({
    "voteCount": {
        "$lt": 40
    }
})
```

#### $lte => Number

Asserts that a value is less than or equal to some specified value.
Examples:
```
collection.find({
    "voteCount": {
        "$lte": 20
    }
})
```

#### $in => Array

Asserts that a value is in a specified list of values.
Examples:
```
collection.find({
    "city": {
        "$in": ["Manchester", "Edinburgh"]
    }
})
```


#### $notin => Array

Asserts that a value is not in a specified list of values.
Examples:
```
collection.find({
    "city": {
        "$notin": ["London", "Glasgow"]
    }
})
```


#### $exists => Boolean

Asserts that the key exists (or doesn't exist).
Examples:
```
collection.find({
    "paymentId": {
        "$exists": true
    }
})
collection.find({
    "paymentId": {
        "$exists": false
    }
})
```

#### $type => String

Asserts that the type of a fields value matches the provided type name.
Valid types: `"object"`, `"string"`, `"boolean"`, `"number"`, `"array"`, `"null"`
Examples:
```
collection.find({
    "specification": {
        "$type": "object"
    }
})
collection.find({
    "specification": {
        "$type": "string"
    }
})
```

#### $like => String

Asserts that a fields string value is 'like' the specified pattern string, following the semantics of PostgreSQL `LIKE` operation.
Examples:
```
collection.find({
    "title": {
        "$like": "%Ruby%"
    }
})
```

#### $regex => String

Asserts that a fields string value matches the provided regex pattern string, following the semantics of PostgreSQL `~` regex operation.
Examples:
```
collection.find({
    "title": {
        "$regex": "^.*Elixir.*$"
    }
})
```

As an example of mixing match queries with advanced query operations, the following query should match all documents which live in either Edinburgh or Glasgow, and have logged in at least twice:
```
users.find({
    "address": {
        "city": {
            "$in": ["Edinburgh", "Glasgow"]
        }
    },
    "loginCount": {
        "$gte": 2
    }
})
```


### Remove

Remove documents matching the query.

Params:
- query::Map

Returns: Number, representing the number of documents removed

Examples:
```
removed = coll.remove({"likes": ["pears"]})
```


### Remove One

Remove one document matching the query.

Params:
- query::Map

Returns: Number, representing the number of documents removed, either one or zero.

Examples:
```
removed = coll.remove_one({"likes": ["pears"]})
```


### Remove One By Id

Remove one document by its `_id` field.

Params:
- id::String

Returns: Number, representing the number of documents removed, either one or zero.

Examples:
```
removed = coll.remove_one_by_id("abc")
```
