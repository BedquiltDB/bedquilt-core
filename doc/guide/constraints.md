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

Both `$required` and `$notnull` accept boolean values, indicating that the constraint
should be enforced. Silly constraints such as `{'$required': False}` and
`{'$notnull': False}` are simply ignored.

The `$type` constraint accepts a string value describing the data-type that should
be enforced. Valid types are `"string"'`, `"number"`, `"object"`,
`"array"`, and `"boolean"`.

The `add_constraints` operation is idempotent. If you add the same constraint twice,
the second operation simply does nothing. `add_constraints` returns a boolean value indicating whether any new constraints were applied to the collection.


## Listing Constraints on a Collection

The `list_constraints` operation returns a list of strings describing the constraints
that are currently in effect on a collection. Example:

```python
print db['users'].list_constraints()
# => ['email:required', 'email:notnull', 'email:type:string', ...]
```

This should only be used for database administration, as the format of the
data returned from `list_collections` is subject to change in future versions
of BedquiltDB.


## Removing Constraints

To remove constraints from a collection, use the `remove_constraints` operation,
passing it the same constraint spec document that was used to create the constraints.
For example, to remove the constraints on the `name` field we added earlier,
we could do the following:

```python
db['users'].remove_constraints({
    'name': {
        '$required': True,
        '$type': 'string'
    }
})
```

Just like `add_constraints`, `remove_constraints` is idempotent. If a constraint
does not already exist, then `remove_constraints` just does nothing.
The `remove_constraints` operation returns a boolean to indicate whether any of the
specified constraints were actually removed.
