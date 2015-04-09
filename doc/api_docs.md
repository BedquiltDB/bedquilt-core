# Core API

This page describes the sql functions which make up the bedquilt extension.


---- ---- ---- ----




### bq\_doc\_set\_key

language: plpgsql

params: None

returns: None




### bq\_check\_id\_type

language: plpgsql

params: [['i_jdoc', 'json']]

returns: None




### bq\_create\_collection

language: plpgsql

params: [['i_coll', 'text']]

returns: None




### bq\_list\_collections

language: plpgsql

params: None

returns: None




### bq\_delete\_collection

language: plpgsql

params: [['i_coll', 'text']]

returns: None




### bq\_find\_one\_by\_id

language: plpgsql

params: None

returns: None




### bq\_find

language: plpgsql

params: None

returns: None




### bq\_remove

language: plpgsql

params: [['i_coll', 'text'], ['i_jdoc', 'json']]

returns: setof integer




### bq\_remove\_one

language: plpgsql

params: [['i_coll', 'text'], ['i_jdoc', 'json']]

returns: setof integer




### bq\_remove\_one\_by\_id

language: plpgsql

params: [['i_coll', 'text'], ['i_id', 'text']]

returns: setof boolean




### bq\_save

language: plpgsql

params: [['i_coll', 'text'], ['i_jdoc', 'json']]

returns: text
