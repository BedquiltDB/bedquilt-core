# Core API

This page describes the sql functions which make up the bedquilt extension.


---- ---- ---- ----




## bq\_generate\_id 

- params: `None`
- returns: `char(24)`
- language: `plpgsql`

Generate a random string ID.
Used by the insert function to populate the '_id' field if missing.





## bq\_doc\_set\_key

- params: `i_jdoc json, i_key text, i_val anyelement`
- returns: `json`
- language: `plpgsql`

Set a key in a json document.





## bq\_collection\_exists 

- params: `None`
- returns: `boolean`
- language: `plpgsql`

Check if a collection exists.
Currently does a simple check for a table with the specified name.




## bq\_check\_id\_type

- params: `i_jdoc json`
- returns: `VOID`
- language: `plpgsql`

Ensure the _id field of the supplied json document is a string value.
If it's not, an exception is raised. Ideally, the client should validate
this is the case before submitting to the server.





## bq\_create\_collection

- params: `i_coll text`
- returns: `BOOLEAN`
- language: `plpgsql`

Create a collection with the specified name





## bq\_list\_collections

- params: `None`
- returns: `table(collection_name text)`
- language: `plpgsql`

Get a list of existing collections.
This checks information_schema for tables matching the expected structure.





## bq\_delete\_collection

- params: `i_coll text`
- returns: `BOOLEAN`
- language: `plpgsql`

Delete/drop a collection.
At the moment, this just drops whatever table matches the collection name.





## bq\_find\_one\_by\_id

- params: `i_coll text, i_id text`
- returns: `table(bq_jdoc json)`
- language: `plpgsql`






## bq\_find

- params: `i_coll text, i_json_query json`
- returns: `table(bq_jdoc json)`
- language: `plpgsql`

find many documents





## bq\_insert

- params: `i_coll text, i_jdoc json`
- returns: `text`
- language: `plpgsql`

insert document





## bq\_remove

- params: `i_coll text, i_jdoc json`
- returns: `setof integer`
- language: `plpgsql`

remove documents





## bq\_remove\_one

- params: `i_coll text, i_jdoc json`
- returns: `setof integer`
- language: `plpgsql`

remove one document





## bq\_remove\_one\_by\_id

- params: `i_coll text, i_id text`
- returns: `setof boolean`
- language: `plpgsql`

remove one document





## bq\_save

- params: `i_coll text, i_jdoc json`
- returns: `text`
- language: `plpgsql`

save document



