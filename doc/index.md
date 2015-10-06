# BedquiltDB


This is the documentation for the core [BedquiltDB](http://bedquiltdb.github.io)
PostgreSQL extension.

BedquiltDB is a JSON document store built on top of PostgreSQL. It combines the
ease-of-use of NoSQL document stores with the integrety and stability of PostgreSQL.

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

## Sections

### [BedquiltDB Guide](guide/index.md)

### [Getting Started](getting_started.md)

### [Core API](api_docs.md)

### [Spec](spec.md)
