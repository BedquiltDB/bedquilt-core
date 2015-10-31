# BedquiltDB


This is the documentation for the core [BedquiltDB](http://bedquiltdb.github.io)
PostgreSQL extension.

BedquiltDB is a JSON document store built on top of PostgreSQL. It combines the
ease-of-use of NoSQL document stores with the integrity and stability of PostgreSQL.

You should probably start with the [General Concepts](guide/concepts.md)
section of the [BedquiltDB Guide](guide/index.md) .

```python
# Example in Python
db = BedquiltClient(dbname="example")

users = db['users']

users.insert({
    "name": "Sarah Jones",
    "email": "sarah@example.com",
    "address": {
        "street": "4 Market Lane",
        "city": "Edinburgh"
    }
})

sarah = users.find_one({"email": "sarah@example.com"})
sarah['likes'] = ['icecream', 'code']
users.save(sarah)
```

BedquiltDB is open-source software. The source-code is freely available
on [github](https://github.com/BedquiltDB).

## Sections

### [BedquiltDB Guide](guide/index.md)

### [Getting Started](getting_started.md)

### [Core API](api_docs.md)

### [Spec](spec.md)
