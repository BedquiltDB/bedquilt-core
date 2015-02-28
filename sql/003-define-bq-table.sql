DROP FUNCTION IF EXISTS bq_define_table(t_name text);

CREATE OR REPLACE FUNCTION bq_define_table(t_name text)
RETURNS VOID AS $$
BEGIN

EXECUTE format('
  CREATE TABLE IF NOT EXISTS %I (
      id serial PRIMARY KEY,
      payload jsonb,
      created timestamptz default current_timestamp,
      updated timestamptz default current_timestamp
  )', t_name);

END
$$ LANGUAGE plpgsql;
