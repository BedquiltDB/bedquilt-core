DROP FUNCTION IF EXISTS bq_define_table(t_name text);

CREATE OR REPLACE FUNCTION bq_define_table(t_name text)
RETURNS VOID AS $$
BEGIN

EXECUTE format('
  CREATE TABLE IF NOT EXISTS %I (
      id serial PRIMARY KEY,
      payload jsonb,
      created timestamptz default current_timestamp,
      updated timestamptz default current_timestamp,
      CONSTRAINT validate_id CHECK ((payload->>''_id'') IS NOT NULL)
  );
  CREATE INDEX idxgin ON %I USING gin (payload);
  CREATE UNIQUE INDEX ui_id ON %I ((payload->>''_id''));
  ', t_name, t_name, t_name);

END
$$ LANGUAGE plpgsql;
