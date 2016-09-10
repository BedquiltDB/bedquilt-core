# BedquiltDB Spec


## Overview

This document specifies a high-level interface to BedquiltDB.
The examples will be given in a pseudo-python language.


## Connections

The semantics of a "Connection" are left to the client library to decide. In general, the following code example should be considered typical for an imperative language like Python or Ruby:

```
db = bedquilt.BedquiltClient("localhost/bedquilt_test")
people = db['people']
```

Because most/all BedquiltDB clients will be wrappers around that languages PostgreSQL library, it is likely that the semantics of creating a connection, including the connection-string specification, will mirror the semantics of that underlying library.


## Database Operations

A Database is presumed to correspond to a PostgreSQL Database object.

### Create Collection

Create a collection. Does nothing if the collection already exists.

Params:

- collectionName::String

Returns: Boolean indicating whether the collection was created.

Examples:
```
db.create_collection("people")
```


### Delete Collection

Delete a collection. Does nothing if the collection does not exist.

Params:

- collectionName::String

Returns: Boolean indicating whether the collection was deleted.

Examples:
```
db.delete_collection("people")
```


### List Collections

Get a list of collection names.

Params: None

Returns: List of string names of collections.

Examples:
```
for collection_name in db.list_collections():
    print collection_name
```


### Collection Exists

Check if a collection exists.

Params:

- collectionName::String

Examples:
```
db.collection_exists('people')
```


### List Constraints

Get a list of constraints on a collection. The return value is a list of strings which should be meaningful to humans, but not necessarily meaningful to the BedquiltDB API.

Examples:
```
coll.list_constraints()
```

Returns: Boolean indicating whether the collection exists


## Collection Operations

A collection is a named bucket in which JSON documents (objects) can be stored. The following assumptions are made about documents within a collection:

- Each document must have a `_id` ("underscore eye-dee") field at the top level, whose value is a String.
- If a document is written to a collection, but does not contain a `_id` field, then the server will randomly generate one and add it to the document before persisting to storage.
- Each documents `_id` field must be unique. Each `_id` value is presumed to uniquely identify a logical document

In broad terms, the following pseudo-code should store a JSON document in the `people` collection:
```
people = db['people']
sarah = {
    '_id': 'abcd',
    'name': 'Sarah',
    'likes': ['icecream', 'code']
}
people.insert(sarah)
```


### Add Constraints

Adds a constraint to the fields of this collection.  The spec
describes the fields which should be constrained, and how. This will
validate all existing documents in the collection before
applying. Further writes to this collection will be validated before
writing, and will fail (raise an error) if the written document does not satisfy the
constraints.

Spec Options:
- $required (Boolean) : Enforces that this
  field must be present in all documents
- $notnull (Boolean) : Field must never have a null value
- $type (String) : enforce the type of this field,
  options are "string", "number|double|float",  "array", "object"

Params:

- spec::Map

Returns: Boolean indicating whether any constraints were added or not.

Examples:
```
coll.add_constraint({"name": {"$required": True,
                              "$notnull": True,
                              "$type": "string",
                              "$unique": False}})
```


### Remove Constraints

Removes constraints, if they exist, on a collection. Removing constraints which don't exist is a no-op. Should use the same constraint spec documents as for creating constraints.

Params:

- spec::Map

Returns: Boolean indicating whether any constraints were removed or not.

Examples:
```
coll.remove_constraint({
    "name": {"$required": True}
})
```


### List Constraints

Get a list of constraints on a collection. The return value is a list of strings which should be meaningful to humans, but not necessarily meaningful to the BedquiltDB API.

Examples:
```
coll.list_constraints()
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
"sort by age, then by name". Two 'special' sorts are available: `$created`, and `$updated`.
The `$created` sort will sort documents by their creation timestamp, while `$updated` will sort by the time the documents were updated. These sorts should use hidden metadata which is not ordinarily available for querying.

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

coll.find(
    {"likes": ["icecream"]},
    sort=[{"age": 1, "$updated": -1}]
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


### Count

Get a count of documents in a collection, matching a query document.

Params:

- query::Map

Returns: Integer indicating count of documents matching the query

Examples:
```
coll.count({"active": True})
```


### Distinct

Get a list of distinct values which exist at some path in a collection. The path is a string representing a dotted-path into the collections documents. For example, to retrieve the list of distinct cities that users live in, the `city` field, within the `address` field, within the `users` collection, would be represented as `"address.city"`.

Params:

- path::String

Examples:
```
users = db['users']
users.distinct('address.city')    # => ['Edinburgh', 'Glasgow', ...]
users.distinct('lastName')        # => ['Smith', 'Clarke', ...]
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


### Remove Many By Ids

Remove many documents by their `_id` fields.

Params:

- id::Array

Returns: Number, representing the number of documents removed, either one or zero.

Examples:
```
removed = coll.remove_many_by_ids(["one", "two", "four"])
```


----
