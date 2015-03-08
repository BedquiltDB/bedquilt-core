-- Document Writes


-- insert document
CREATE OR REPLACE FUNCTION bq_insert_document(
    i_coll text,
    i_json_data json
) RETURNS VOID AS $$
BEGIN

PERFORM bq_create_collection(i_coll);

EXECUTE format(
    'INSERT INTO %I (jdoc) VALUES (''%s'');',
    i_coll,
    i_json_data
);

END
$$ LANGUAGE plpgsql;
