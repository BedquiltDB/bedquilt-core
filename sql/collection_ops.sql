DROP FUNCTION IF EXISTS bq_create_collection(t_name text);

CREATE OR REPLACE FUNCTION bq_create_collection(t_name text)
RETURNS VOID AS $$
BEGIN

EXECUTE format('
  CREATE TABLE IF NOT EXISTS %1$I (
      id serial PRIMARY KEY,
      payload jsonb,
      created timestamptz default current_timestamp,
      updated timestamptz default current_timestamp,
      CONSTRAINT validate_id CHECK ((payload->>''_id'') IS NOT NULL)
  );
  CREATE INDEX idx_%1$I_payload ON %1$I USING gin (payload);
  CREATE UNIQUE INDEX idx_%1$I_payload_id ON %1$I ((payload->>''_id''));
  ', t_name);

END
$$ LANGUAGE plpgsql;
