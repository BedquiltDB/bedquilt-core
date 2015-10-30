# Guide: Constraints


## Overview

By default, BedquiltDB collections do not enforce any schema on the documents
they contain. The only demand BedquiltDB makes of a document is that it have a `_id`
field. While this looseness is useful, most of the time we have a good idea of the
"shape" of our data and would like to enforce at least some kind of schema.

BedquiltDB allows you to add constraints to a collection. Once the constraint is in
place, any documents written to the collection are checked against the constraints
to see if they are valid. If the data fits the constraints, the data is written as
normal, otherwise an error is raised.


## Adding Constraints to Collections

Constraints are added to a collection with the `add_constraints` operation.
A constraint specifies the field to be constrained, and in what ways the field should
be validated. Let's look at an example (in python):

```python
db = pybedquilt.BedquiltClient(dbname='test')
db['users'].add_constraint({
    'email': {
        '$required': True,
        '$notnull': True,
        '$type': 'string'
    },
    'password_hash': {
        '$required': True,
        '$notnull': True,
        '$type': 'string'
    },
    'name': {
        '$required': True,
        '$type': 'string'
    },
    'loginCount': {
        '$type': 'number'
    }
})
```

The only parameter to `add_constraints` operation is a json document specifying the
constraints to be added. The keys of the spec document are the fields to be
constrained, and the values are json objects describing the kind of validation
operations to be applied to that field.

There are three validations which can be applied, in any combination, to a field:

| Constraint        | Effect                                           |
|-------------------|--------------------------------------------------|
| `$required`       | The field must be present in the document.       |
| `$notnull`        | If the field is present, it must not be null     |
| `$type`           | If the field is present, it must be of this type |


## Removing Constraints
