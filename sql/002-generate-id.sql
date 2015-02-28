DROP FUNCTION IF EXISTS bq_generate_id();

CREATE OR REPLACE FUNCTION bq_generate_id () RETURNS char(24) AS $$
BEGIN
  RETURN CAST(encode(gen_random_bytes(12), 'hex') as char(24));
END
$$ LANGUAGE plpgsql IMMUTABLE STRICT;
