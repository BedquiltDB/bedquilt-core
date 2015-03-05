DROP FUNCTION IF EXISTS bq_insert_document(i_coll text, i_json_query json);

CREATE OR REPLACE FUNCTION bq_findone_document(
    i_coll text,
    i_json_query json
) RETURNS table(jdoc json) AS $$
BEGIN

IF EXISTS (SELECT relname FROM pg_class WHERE relname = format('%s', i_coll))
THEN
    RETURN QUERY EXECUTE format(
        'SELECT payload::json FROM %I
        WHERE payload @> (''%s'')::jsonb
        LIMIT 1',
        i_coll,
        i_json_query
    );
END IF;

END
$$ LANGUAGE plpgsql;
