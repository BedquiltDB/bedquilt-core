CREATE OR REPLACE FUNCTION bq_generate_id () RETURNS text AS $$
BEGIN
  RETURN CAST(encode(gen_random_bytes(12), 'hex') as text);
END
$$ LANGUAGE plpgsql IMMUTABLE STRICT;
