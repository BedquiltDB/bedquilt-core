# Core API

This page describes the sql functions which make up the bedquilt extension.


---- ---- ---- ----




## bq\_generate\_id 

- params: `None`
- returns: `char(24)`
- language: `plpgsql`




## bq\_doc\_set\_key

- params: `i_jdoc json, i_key text, i_val anyelement`
- returns: `json`
- language: `plpgsql`




## bq\_collection\_exists 

- params: `None`
- returns: `boolean`
- language: `plpgsql`




## bq\_check\_id\_type

- params: `i_jdoc json`
- returns: `VOID`
- language: `plpgsql`




## bq\_create\_collection

- params: `i_coll text`
- returns: `BOOLEAN`
- language: `plpgsql`




## bq\_list\_collections

- params: `None`
- returns: `table(collection_name text)`
- language: `plpgsql`




## bq\_delete\_collection

- params: `i_coll text`
- returns: `BOOLEAN`
- language: `plpgsql`




## bq\_find\_one\_by\_id

- params: `i_coll text, i_id text`
- returns: `table(bq_jdoc json)`
- language: `plpgsql`




## bq\_find

- params: `i_coll text, i_json_query json`
- returns: `table(bq_jdoc json)`
- language: `plpgsql`




## bq\_remove

- params: `i_coll text, i_jdoc json`
- returns: `setof integer`
- language: `plpgsql`




## bq\_remove\_one

- params: `i_coll text, i_jdoc json`
- returns: `setof integer`
- language: `plpgsql`




## bq\_remove\_one\_by\_id

- params: `i_coll text, i_id text`
- returns: `setof boolean`
- language: `plpgsql`




## bq\_save

- params: `i_coll text, i_jdoc json`
- returns: `text`
- language: `plpgsql`


