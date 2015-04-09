# Core API

This page describes the sql functions which make up the bedquilt extension.


---- ---- ---- ----




### bq\_generate\_id 

params: None

returns: char(24)

language: plpgsql





### bq\_doc\_set\_key

params: i\_jdoc json, i\_key text, i\_val anyelement)

returns: json

language: plpgsql





### bq\_collection\_exists 

params: None

returns: boolean

language: plpgsql





### bq\_check\_id\_type

params: i\_jdoc json)

returns: VOID

language: plpgsql





### bq\_create\_collection

params: i\_coll text)

returns: BOOLEAN

language: plpgsql SECURITY DEFINER





### bq\_list\_collections

params: )

returns: table(collection\_name text)

language: plpgsql SECURITY DEFINER





### bq\_delete\_collection

params: i\_coll text)

returns: BOOLEAN

language: plpgsql SECURITY DEFINER





### bq\_find\_one\_by\_id

params: i\_coll text, i\_id text)

returns: table(bq\_jdoc json)

language: plpgsql





### bq\_find

params: i\_coll text, i\_json\_query json)

returns: table(bq\_jdoc json)

language: plpgsql





### bq\_remove

params: i\_coll text, i\_jdoc json)

returns: setof integer

language: plpgsql





### bq\_remove\_one

params: i\_coll text, i\_jdoc json)

returns: setof integer

language: plpgsql





### bq\_remove\_one\_by\_id

params: i\_coll text, i\_id text)

returns: setof boolean

language: plpgsql





### bq\_save

params: i\_coll text, i\_jdoc json)

returns: text

language: plpgsql



