# API Docs

This document is auto-generated from the core `bedquilt` source code, and describes the low-level SQL API of BedquiltDB.

---- ---- ---- ----


# collection_constraints

## bq\_add\_constraints

- params: `i_coll text, i_jdoc jsonb`
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
Example:
  select bq_add_constraints('things', '{"name": {"$required": true}}')
```



## bq\_remove\_constraints

- params: `i_coll text, i_jdoc jsonb`
- returns: `boolean`
- language: `plpgsql`

```markdown
Remove constraints from collection.
The supplied json document should match the spec for existing constraints.
Returns True if any of the constraints were removed, False otherwise.
Example:
  select bq_remove_constraints('things', '{"name": {"$required": true}}')
```



## bq\_list\_constraints

- params: `i_coll text`
- returns: `setof text`
- language: `plpgsql`

```markdown
Get a list of text descriptions of constraints on this collection.
Example:
  select bq_list_constraints('orders')
```



# collection_ops

## bq\_create\_collection

- params: `i_coll text`
- returns: `BOOLEAN`
- language: `plpgsql`

```markdown
Create a collection with the specified name.
Example:
  select bq_create_collection('orders');
```



## bq\_list\_collections

- params: `None`
- returns: `table(collection_name text)`
- language: `plpgsql`

```markdown
Get a list of existing collections.
This checks information_schema for tables matching the expected structure.
Example:
  select bq_list_collections();
```



## bq\_delete\_collection

- params: `i_coll text`
- returns: `BOOLEAN`
- language: `plpgsql`

```markdown
Delete/drop a collection.
At the moment, this just drops whatever table matches the collection name.
Example:
  select bq_delete_collection('orders');
```



## bq\_collection\_exists 

- params: `None`
- returns: `boolean`
- language: `plpgsql`

```markdown
Check if a collection exists.
Example:
  select bq_collection_exists('orders');
```



# document_reads

## bq\_find\_one

- params: `i_coll text, i_json_query jsonb, i_skip integer DEFAULT 0, i_sort jsonb DEFAULT null`
- returns: `table(bq_jdoc jsonb)`
- language: `plpgsql`

```markdown
Find one document from a collection, matching a query document.
Effectively the same as bq_find with limit set to 1.
Params:
  - i_coll: collection name
  - i_json_query: the query document
  - i_skip: (optional) number of documents to skip, default 0
  - i_sort: (optional) json array of sort specifications, default null
Example:
  select bq_find_one('orders', '{"processed": false}');
```



## bq\_find\_one\_by\_id

- params: `i_coll text, i_id text`
- returns: `table(bq_jdoc jsonb)`
- language: `plpgsql`

```markdown
Find a single document from a collection, by it's `_id` property.
This function is potentially faster than the equivalent call to bq_find_one
with a '{"_id": "..."}' query document.
Example:
  select bq_find_one_by_id('things', 'fa0c852e4bc5d384b5f9fde5');
```



## bq\_find

- params: `i_coll text, i_json_query jsonb, i_skip integer DEFAULT 0, i_limit integer DEFAULT null, i_sort jsonb DEFAULT null`
- returns: `table(bq_jdoc jsonb)`
- language: `plpgsql`

```markdown
Find documents from a collection, matching a query document.
Params:
  - i_coll: collection name
  - i_json_query: the query document
  - i_skip: (optional) number of documents to skip, default 0
  - i_limit: (optional) number of documents to limit the result set to,
  - i_sort: (optional) json array of sort specifications, default null
Example:
  select bq_find('orders', '{"processed": false}');
  select bq_find('orders', '{"processed": false}', 2, 10, '[{"orderTime": -1}]');
```



## bq\_count

- params: `i_coll text, i_doc jsonb`
- returns: `integer`
- language: `plpgsql`

```markdown
Count documents in a collection, matching a query document.
Example:
  select bq_countt('orders', '{"processed": true}')
```



## bq\_distinct

- params: `i_coll text, i_key_path text`
- returns: `table(val jsonb)`
- language: `plpgsql`

```markdown
Get a sequence of the distinct values present in the collection for a given key,
Example:
  select bq_distinct('people', 'address.city')
```



# document_writes

## bq\_insert

- params: `i_coll text, i_jdoc jsonb`
- returns: `text`
- language: `plpgsql`

```markdown
Insert a document into a collection.
Raises an error if a document already exists with the same `_id` field.
If the document doesn't contain an `_id` field, then one will be randomly generated
Example:
  select bq_insert('things', '{"name": "wrench"}');
```



## bq\_remove

- params: `i_coll text, i_jdoc jsonb`
- returns: `setof integer`
- language: `plpgsql`

```markdown
Remove documents from a collection, matching a query document.
Returns count of deleted documents.
Example:
  select bq_remove('orders', '{"cancelled": true}');
```



## bq\_remove\_one

- params: `i_coll text, i_jdoc jsonb`
- returns: `setof integer`
- language: `plpgsql`

```markdown
Remove a single document from a collection, matching a query document.
The first document to match the query will be removed.
Returns count of deleted documents, either one or zero.
Example:
  select bq_remove_one('orders', '{"cancelled": true}');
```



## bq\_remove\_one\_by\_id

- params: `i_coll text, i_id text`
- returns: `setof integer`
- language: `plpgsql`

```markdown
Remove a single document from a collection, by its `_id` field.
Returns count of deleted documents, either one or zero.
Example:
  select bq_remove_one_by_id('orders', '4d733fb148e7d89f7c569655');
```



## bq\_remove\_many\_by\_ids

- params: `i_coll text, i_ids jsonb`
- returns: `setof integer`
- language: `plpgsql`

```markdown
Remove many documents, by their `_id` fields.
```



## bq\_save

- params: `i_coll text, i_jdoc jsonb`
- returns: `text`
- language: `plpgsql`

```markdown
Save a document to a collection.
Similar to `bq_insert`, but will overwrite an existing document if one with a matching
`_id` field is found. Can be used to either create new documents or update existing documents.
Example:
  select bq_save('things', '{"_id": "abc", "name": "wrench"}');
```



# utilities

## bq\_util\_generate\_id 

- params: `None`
- returns: `char(24)`
- language: `plpgsql`

```markdown
Generate a random string ID.
Used by the document write functions to populate the '_id' field
if it is missing.
```

