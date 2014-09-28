CREATE OR REPLACE FUNCTION bq_generate_id () RETURNS text AS $$
BEGIN
  RETURN SELECT CAST(encode(gen_random_bytes(8), 'hex') as text;
END
$$ LANGUAGE plpgsql IMMUTABLE STRICT;
