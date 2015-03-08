-- Bedquilt init


-- dependencies
CREATE EXTENSION IF NOT EXISTS pgcrypto;


-- bedquilt version
CREATE OR REPLACE FUNCTION bq_version () RETURNS VARCHAR AS $$
BEGIN
RETURN '0.1.0';
END
$$ LANGUAGE plpgsql IMMUTABLE STRICT;
