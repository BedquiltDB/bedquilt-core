DROP FUNCTION IF EXISTS bq_insert_document(i_coll text, i_json_query json);

CREATE OR REPLACE FUNCTION bq_findone_document(
    i_coll text,
    i_json_query json
) RETURNS table(jdoc json) AS $$
BEGIN

EXECUTE format(
    'SELECT payload FROM %I
     WHERE payload @> (''%s'')::jsonb
     LIMIT 1',
     i_coll,
     i_json_query
 );

END
$$ LANGUAGE plpgsql;
