-- Bedquilt Extension


-- bedquilt version
CREATE OR REPLACE FUNCTION bq_version () RETURNS VARCHAR AS $$
BEGIN
RETURN '0.1.0';
END
$$ LANGUAGE plpgsql IMMUTABLE STRICT;


-- Utilities

-- generate id
CREATE OR REPLACE FUNCTION bq_generate_id () RETURNS char(24) AS $$
BEGIN
RETURN CAST(encode(gen_random_bytes(12), 'hex') as char(24));
END
$$ LANGUAGE plpgsql IMMUTABLE STRICT;


-- collection exists
CREATE OR REPLACE FUNCTION bq_collection_exists (i_coll text)
RETURNS boolean AS $$
BEGIN

RETURN EXISTS (
    SELECT relname FROM pg_class WHERE relname = format('%s', i_coll)
);

END
$$ LANGUAGE plpgsql IMMUTABLE STRICT;


-- Collection-level operations

-- create collection
CREATE OR REPLACE FUNCTION bq_create_collection(i_coll text)
RETURNS BOOLEAN AS $$
BEGIN

IF NOT (SELECT bq_collection_exists(i_coll))
THEN
    EXECUTE format('
    CREATE TABLE IF NOT EXISTS %1$I (
        id serial PRIMARY KEY,
        bq_jdoc jsonb,
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
    EXECUTE format('DROP TABLE %I;', i_coll);
    RETURN true;
ELSE
    RETURN false;
END IF;

END
$$ LANGUAGE plpgsql;


-- Document Reads

-- find one
CREATE OR REPLACE FUNCTION bq_findone_document(
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


-- find many documents
CREATE OR REPLACE FUNCTION bq_find_documents(
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


-- Document Writes

-- insert document
CREATE OR REPLACE FUNCTION bq_insert_document(
    i_coll text,
    i_json_data json
) RETURNS VOID AS $$
BEGIN

PERFORM bq_create_collection(i_coll);

EXECUTE format(
    'INSERT INTO %I (bq_jdoc) VALUES (''%s'');',
    i_coll,
    i_json_data
);

END
$$ LANGUAGE plpgsql;
