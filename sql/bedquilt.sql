-- # -- # -- # -- # -- #
-- Bedquilt Extension
-- # -- # -- # -- # -- #

-- bedquilt version
CREATE OR REPLACE FUNCTION bq_version () RETURNS VARCHAR AS $$
BEGIN
RETURN '0.1.0';
END
$$ LANGUAGE plpgsql;


-- # -- # -- # -- # -- #
-- Utilities
-- # -- # -- # -- # -- #

-- generate id
CREATE OR REPLACE FUNCTION bq_generate_id () RETURNS char(24) AS $$
BEGIN
RETURN CAST(encode(gen_random_bytes(12), 'hex') as char(24));
END
$$ LANGUAGE plpgsql;


-- set key
CREATE OR REPLACE FUNCTION bq_doc_set_key(
    i_jdoc json,
    i_key  text,
    i_val  anyelement
)
RETURNS json
AS $$
BEGIN
RETURN (SELECT concat('{', string_agg(to_json("key") || ':' || "value", ','), '}')::json
    FROM (SELECT *
    FROM json_each(i_jdoc)
    WHERE key <> i_key
    UNION ALL
    SELECT i_key, to_json(i_val)) as "fields")::json;
END
$$ LANGUAGE plpgsql;


-- collection exists
CREATE OR REPLACE FUNCTION bq_collection_exists (i_coll text)
RETURNS boolean AS $$
BEGIN

RETURN EXISTS (
    SELECT relname FROM pg_class WHERE relname = format('%s', i_coll)
);

END
$$ LANGUAGE plpgsql;


-- # -- # -- # -- # -- #
-- Collection-level operations
-- # -- # -- # -- # -- #

-- create collection
CREATE OR REPLACE FUNCTION bq_create_collection(i_coll text)
RETURNS BOOLEAN AS $$
BEGIN

IF NOT (SELECT bq_collection_exists(i_coll))
THEN
    EXECUTE format('
    CREATE TABLE IF NOT EXISTS %1$I (
        _id varchar(256) PRIMARY KEY NOT NULL,
        bq_jdoc jsonb NOT NULL,
        created timestamptz default current_timestamp,
        updated timestamptz default current_timestamp,
        CONSTRAINT validate_id CHECK ((bq_jdoc->>''_id'') IS NOT NULL)
    );
    COMMENT ON TABLE %1$I IS ''bedquilt.%1$s'';
    CREATE INDEX idx_%1$I_bq_jdoc ON %1$I USING gin (bq_jdoc);
    CREATE UNIQUE INDEX idx_%1$I_bq_jdoc_id ON %1$I ((bq_jdoc->>''_id''));

    ', i_coll);
    RETURN true;
ELSE
    RETURN false;
END IF;

END
$$ LANGUAGE plpgsql;


-- list collections
CREATE OR REPLACE FUNCTION bq_list_collections()
RETURNS table(collection_name text) AS $$
BEGIN

RETURN QUERY SELECT table_name::text
       FROM information_schema.columns
       WHERE column_name = 'bq_jdoc'
       AND data_type = 'jsonb';

END
$$ LANGUAGE plpgsql;


-- delete collection
CREATE OR REPLACE FUNCTION bq_delete_collection(i_coll text)
RETURNS BOOLEAN AS $$
BEGIN

IF (SELECT bq_collection_exists(i_coll))
THEN
    EXECUTE format('DROP TABLE %I CASCADE;', i_coll);
    RETURN true;
ELSE
    RETURN false;
END IF;

END
$$ LANGUAGE plpgsql;


-- # -- # -- # -- # -- #
-- Document Reads
-- # -- # -- # -- # -- #

-- find one
CREATE OR REPLACE FUNCTION bq_find_one(
    i_coll text,
    i_json_query json
) RETURNS table(bq_jdoc json) AS $$
BEGIN

IF (SELECT bq_collection_exists(i_coll))
THEN
    RETURN QUERY EXECUTE format(
        'SELECT bq_jdoc::json FROM %I
        WHERE bq_jdoc @> (''%s'')::jsonb
        LIMIT 1',
        i_coll,
        i_json_query
    );
END IF;

END
$$ LANGUAGE plpgsql;


-- find one by id
CREATE OR REPLACE FUNCTION bq_find_one_by_id(
    i_coll text,
    i_id text
) RETURNS table(bq_jdoc json) AS $$
BEGIN

IF (SELECT bq_collection_exists(i_coll))
THEN
    RETURN QUERY EXECUTE format(
        'SELECT bq_jdoc::json FROM %I
        WHERE _id = ''%s''
        LIMIT 1',
        i_coll,
        i_id
    );
END IF;

END
$$ LANGUAGE plpgsql;


-- find many documents
CREATE OR REPLACE FUNCTION bq_find(
    i_coll text,
    i_json_query json
) RETURNS table(bq_jdoc json) AS $$
BEGIN

IF (SELECT bq_collection_exists(i_coll))
THEN
    RETURN QUERY EXECUTE format(
        'SELECT bq_jdoc::json FROM %I
        WHERE bq_jdoc @> (''%s'')::jsonb',
        i_coll,
        i_json_query
    );
END IF;

END
$$ LANGUAGE plpgsql;


-- # -- # -- # -- # -- #
-- Document Writes
-- # -- # -- # -- # -- #

-- insert document
CREATE OR REPLACE FUNCTION bq_insert(
    i_coll text,
    i_json_data json
) RETURNS text AS $$
DECLARE
  doc json;
BEGIN

PERFORM bq_create_collection(i_coll);

IF (select i_json_data->'_id') is null
THEN
  select bq_doc_set_key(i_json_data, '_id', (select bq_generate_id())) into doc;
ELSE
  select i_json_data into doc;
END IF;

EXECUTE format(
    'INSERT INTO %I (_id, bq_jdoc) VALUES (''%s'', ''%s'');',
    i_coll,
    doc->>'_id',
    doc
);

return doc->>'_id';

END
$$ LANGUAGE plpgsql;


-- remove document
CREATE OR REPLACE FUNCTION bq_remove(i_coll text, i_json_data json, i_multi boolean)
RETURNS setof integer as $$
BEGIN

IF i_multi
THEN
    RETURN QUERY EXECUTE format('
    WITH deleted AS (DELETE FROM %I WHERE bq_jdoc @> (''%s'')::jsonb
    RETURNING _id)
    SELECT count(*)::integer FROM deleted
    ', i_coll, i_json_data);
ELSE
    RETURN QUERY EXECUTE format('
    WITH candidates AS
         (SELECT _id from %1$I WHERE bq_jdoc @> (''%2s'')::jsonb LIMIT 1),
         deleted AS
         (DELETE FROM %1$I WHERE _id IN (select _id from candidates) RETURNING _id)
    SELECT count(*)::integer FROM deleted
    ', i_coll, i_json_data);
END IF;

END
$$ LANGUAGE plpgsql;
