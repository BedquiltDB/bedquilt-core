# API Docs

This document is auto-generated from the core `bedquilt` source code, and describes the low-level SQL API of BedquiltDB.

---- ---- ---- ----




## bq\_add\_constraints

- params: `i_coll text, i_jdoc json`
- returns: `boolean`
- language: `plpgsql`

```markdown
Add a set of constraints to the collection.
The supplied json document should be in the form {field: constraint_spec},
for example:
  {"age": {"$required": true,
           "$notnull": true,
           "$type": "number"}}
Valid constraints are: $required, $notnull and $type.
- {$required: 1} : the field must be present in all documents
- {$notnull: 1} : if the field is present, its value must not be null
- {$type: '<type>'} : if the field is present and has a non-null value,
      then the type of that value must match the specified type.
      Valid types are "string", "number", "object", "array", "boolean".
Returns a boolean indicating whether any of the constraints newly applied.

```



## bq\_remove\_constraints

- params: `i_coll text, i_jdoc json`
- returns: `boolean`
- language: `plpgsql`

```markdown
Remove constraints from collection.
The supplied json document should match the spec for existing constraints.
Returns True if any of the constraints were removed, False otherwise.

```



## bq\_list\_constraints

- params: `i_coll text`
- returns: `setof text`
- language: `plpgsql`

```markdown
Get a list of text descriptions of constraints on this collection.

```





## bq\_create\_collection

- params: `i_coll text`
- returns: `BOOLEAN`
- language: `plpgsql`

```markdown
Create a collection with the specified name

```



## bq\_list\_collections

- params: `None`
- returns: `table(collection_name text)`
- language: `plpgsql`

```markdown
Get a list of existing collections.
This checks information_schema for tables matching the expected structure.

```



## bq\_delete\_collection

- params: `i_coll text`
- returns: `BOOLEAN`
- language: `plpgsql`

```markdown
Delete/drop a collection.
At the moment, this just drops whatever table matches the collection name.

```





## bq\_find\_one

- params: `i_coll text, i_json_query json, i_skip integer DEFAULT 0, i_sort json DEFAULT null`
- returns: `table(bq_jdoc json)`
- language: `plpgsql`

```markdown
find one

```



## bq\_find\_one\_by\_id

- params: `i_coll text, i_id text`
- returns: `table(bq_jdoc json)`
- language: `plpgsql`

```markdown

```



## bq\_find

- params: `i_coll text, i_json_query json, i_skip integer DEFAULT 0, i_limit integer DEFAULT null, i_sort json DEFAULT null`
- returns: `table(bq_jdoc json)`
- language: `plpgsql`

```markdown
find many documents

```



## bq\_count

- params: `i_coll text, i_doc json`
- returns: `integer`
- language: `plpgsql`

```markdown
count documents in collection

```



## bq\_distinct

- params: `i_coll text, i_key_path text`
- returns: `table(val jsonb)`
- language: `plpgsql`

```markdown
Get a sequence of the distinct values present in the collection for a given key,
example: bq_distinct('people', 'address.city')

```





## bq\_insert

- params: `i_coll text, i_jdoc json`
- returns: `text`
- language: `plpgsql`

```markdown
insert document

```



## bq\_remove

- params: `i_coll text, i_jdoc json`
- returns: `setof integer`
- language: `plpgsql`

```markdown
remove documents

```



## bq\_remove\_one

- params: `i_coll text, i_jdoc json`
- returns: `setof integer`
- language: `plpgsql`

```markdown
remove one document

```



## bq\_remove\_one\_by\_id

- params: `i_coll text, i_id text`
- returns: `setof integer`
- language: `plpgsql`

```markdown
remove one document

```



## bq\_save

- params: `i_coll text, i_jdoc json`
- returns: `text`
- language: `plpgsql`

```markdown
save document

```





## bq\_generate\_id 

- params: `None`
- returns: `char(24)`
- language: `plpgsql`

```markdown
Generate a random string ID.
Used by the document write functions to populate the '_id' field
if it is missing.

```



## bq\_collection\_exists 

- params: `None`
- returns: `boolean`
- language: `plpgsql`

```markdown
Check if a collection exists.
Currently does a simple check for a table with the specified name.

```

