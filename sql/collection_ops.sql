-- Collection-level operations


-- create collection
CREATE OR REPLACE FUNCTION bq_create_collection(i_coll text)
RETURNS VOID AS $$
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
