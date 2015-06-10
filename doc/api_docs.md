# Core API

This page describes the sql functions which make up the bedquilt extension.


---- ---- ---- ----




## bq\_generate\_id 

- params: `None`
- returns: `char(24)`
- language: `plpgsql`

```python
Generate a random string ID.
Used by the insert function to populate the '_id' field if missing.

```



## bq\_collection\_exists 

- params: `None`
- returns: `boolean`
- language: `plpgsql`

```python
Check if a collection exists.
Currently does a simple check for a table with the specified name.

```



## bq\_create\_collection

- params: `i_coll text`
- returns: `BOOLEAN`
- language: `plpgsql`

```python
Create a collection with the specified name

```



## bq\_list\_collections

- params: `None`
- returns: `table(collection_name text)`
- language: `plpgsql`

```python
Get a list of existing collections.
This checks information_schema for tables matching the expected structure.

```



## bq\_delete\_collection

- params: `i_coll text`
- returns: `BOOLEAN`
- language: `plpgsql`

```python
Delete/drop a collection.
At the moment, this just drops whatever table matches the collection name.

```



## bq\_find\_one

- params: `i_coll text, i_json_query json`
- returns: `table(bq_jdoc json)`
- language: `plpgsql`

```python
find one

```



## bq\_find\_one\_by\_id

- params: `i_coll text, i_id text`
- returns: `table(bq_jdoc json)`
- language: `plpgsql`

```python

```



## bq\_find

- params: `i_coll text, i_json_query json`
- returns: `table(bq_jdoc json)`
- language: `plpgsql`

```python
find many documents

```



## bq\_count

- params: `i_coll text, i_doc json`
- returns: `integer`
- language: `plpgsql`

```python
count documents in collection

```



## bq\_insert

- params: `i_coll text, i_jdoc json`
- returns: `text`
- language: `plpgsql`

```python
insert document

```



## bq\_remove

- params: `i_coll text, i_jdoc json`
- returns: `setof integer`
- language: `plpgsql`

```python
remove documents

```



## bq\_remove\_one

- params: `i_coll text, i_jdoc json`
- returns: `setof integer`
- language: `plpgsql`

```python
remove one document

```



## bq\_remove\_one\_by\_id

- params: `i_coll text, i_id text`
- returns: `setof integer`
- language: `plpgsql`

```python
remove one document

```



## bq\_save

- params: `i_coll text, i_jdoc json`
- returns: `text`
- language: `plpgsql`

```python
save document

```



## bq\_add\_constraint

- params: `i_coll text, i_jdoc json`
- returns: `boolean`
- language: `plpgsql`

```python
Add a set of constraints to the collection.
The supplied json document should be in the form {field: constraint_spec},
for example: {"age": {"$required": 1, "$notnull": 1, "$type": "number"}}.
Valid constraints are: $required, $notnull and $type.
- $required: the field must be present in all documents
- $notnull: if the field is present, its value must not be null
- $type: if the field is present and has a non-null value, then the type
    of that value must match the specified type.
    Valid types are "string", "number", "object", "array", "boolean".

```



## bq\_remove\_constraint

- params: `i_coll text, i_jdoc json`
- returns: `boolean`
- language: `plpgsql`

```python
remove constraints from collection

```



## bq\_list\_constraints

- params: `i_coll text`
- returns: `setof text`
- language: `plpgsql`

```python
get a list of constraints on this collection

```

