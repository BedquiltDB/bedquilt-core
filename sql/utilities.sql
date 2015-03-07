DROP FUNCTION IF EXISTS bq_generate_id();

CREATE OR REPLACE FUNCTION bq_generate_id () RETURNS char(24) AS $$
BEGIN
  RETURN CAST(encode(gen_random_bytes(12), 'hex') as char(24));
END
$$ LANGUAGE plpgsql IMMUTABLE STRICT;


CREATE OR REPLACE FUNCTION bq_collection_exists (i_coll text)
RETURNS boolean AS $$
BEGIN

RETURN EXISTS (
    SELECT relname FROM pg_class WHERE relname = format('%s', i_coll)
);

END
$$ LANGUAGE plpgsql IMMUTABLE STRICT;
