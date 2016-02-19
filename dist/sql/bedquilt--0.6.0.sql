-- # -- # -- # -- # -- #
-- Constraints
-- # -- # -- # -- # -- #


/* Add a set of constraints to the collection.
 * The supplied json document should be in the form {field: constraint_spec},
 * for example:
 *   {"age": {"$required": true,
 *            "$notnull": true,
 *            "$type": "number"}}
 * Valid constraints are: $required, $notnull and $type.
 * - {$required: 1} : the field must be present in all documents
 * - {$notnull: 1} : if the field is present, its value must not be null
 * - {$type: '<type>'} : if the field is present and has a non-null value,
 *       then the type of that value must match the specified type.
 *       Valid types are "string", "number", "object", "array", "boolean".
 * Returns a boolean indicating whether any of the constraints newly applied.
 */
CREATE OR REPLACE FUNCTION bq_add_constraints(i_coll text, i_jdoc json)
RETURNS boolean AS $$
DECLARE
  jdoc_keys RECORD;
  field_name text;
  spec json;
  spec_keys RECORD;
  op text;
  new_constraint_name text;
  s_type text;
  result boolean;
BEGIN
  result := false;
  -- loop over the field names
  FOR jdoc_keys IN SELECT * FROM json_object_keys(i_jdoc) LOOP
    field_name := jdoc_keys.json_object_keys;
    spec := i_jdoc->field_name;

    -- for each field name, loop over the constrant ops
    FOR spec_keys IN SELECT * FROM json_object_keys(spec) LOOP
      op := spec_keys.json_object_keys;
      CASE op
      -- $required : the key must be present in the json object
      WHEN '$required' THEN
        new_constraint_name := format(
          'bqcn:%s:required',
          field_name);
        PERFORM bq_create_collection(i_coll);
        IF bq_constraint_name_exists(i_coll, new_constraint_name) = false
        THEN
          IF field_name LIKE '%.%' THEN
            EXECUTE format(
              'alter table %I
              add constraint "%s"
              check (bq_path_exists(''%s'', bq_jdoc));',
              i_coll,
              new_constraint_name,
              field_name);
            result := true;
          ELSE
            EXECUTE format(
              'alter table %I
              add constraint "%s"
              check (bq_jdoc ? ''%s'');',
              i_coll,
              new_constraint_name,
              field_name);
            result := true;
          END IF;
        END IF;
      -- $notnull : the key must be present in the json object
      WHEN '$notnull' THEN
        new_constraint_name := format(
          'bqcn:%s:notnull',
          field_name);
        PERFORM bq_create_collection(i_coll);
        IF bq_constraint_name_exists(i_coll, new_constraint_name) = false
        THEN
          EXECUTE format(
            'alter table %I
            add constraint "%s"
            check (
              jsonb_typeof((bq_jdoc#>''%s'')::jsonb) <> ''null''
            );',
            i_coll,
            new_constraint_name,
            regexp_split_to_array(field_name, '\.'));
          result := true;
        END IF;
      -- $type: enforce type of the specified field
      --   valid values are:
      --   'string' | 'number' | 'object' | 'array' | 'boolean'
      WHEN '$type' THEN
        s_type := spec->>op;
        new_constraint_name := format(
          'bqcn:%s:type:%s',
          field_name, s_type);
        PERFORM bq_create_collection(i_coll);
        IF bq_constraint_name_exists(i_coll, new_constraint_name) = false
        THEN
          IF s_type NOT IN ('string','object','array','boolean','number')
          THEN
            RAISE EXCEPTION
            'Invalid $type ("%") specified for field "%"',
            s_type, field_name
            USING HINT = 'Please specify the name of a json type';
          END IF;
          -- check if we've got a type constraint already
          IF EXISTS(
            SELECT constraint_name
            FROM information_schema.constraint_column_usage
            WHERE table_name = i_coll
            AND constraint_name LIKE 'bqcn:'
            || field_name
            ||':type:%')
          THEN
            RAISE EXCEPTION
            'Contradictory $type "%" constraint on field "%"',
            s_type, field_name
            USING HINT = 'Please remove existing $type constraint';
          END IF;
          EXECUTE format(
            'alter table %I
            add constraint "%s"
            check (
              jsonb_typeof(bq_jdoc#>''%s'') in (''%s'', ''null'')
            );',
            i_coll,
            new_constraint_name,
            regexp_split_to_array(field_name, '\.'),
            s_type);
          result := true;
        END IF;
      END CASE;

    END LOOP;

  END LOOP;

  RETURN result;
END
$$ LANGUAGE plpgsql;


/* private - check if a constraint name exists
 */
CREATE OR REPLACE FUNCTION bq_constraint_name_exists(i_coll text, i_name text)
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS(
    SELECT * FROM information_schema.constraint_column_usage
    WHERE table_name = i_coll
    AND constraint_name = i_name
  );
END
$$ LANGUAGE plpgsql;


/* Remove constraints from collection.
 * The supplied json document should match the spec for existing constraints.
 * Returns True if any of the constraints were removed, False otherwise.
 */
CREATE OR REPLACE FUNCTION bq_remove_constraints(i_coll text, i_jdoc json)
RETURNS boolean AS $$
DECLARE
  jdoc_keys RECORD;
  field_name text;
  spec json;
  spec_keys RECORD;
  op text;
  target_constraint text;
  s_type text;
  result boolean;
BEGIN

  result := false;
  -- loop over the field names
  FOR jdoc_keys IN SELECT * FROM json_object_keys(i_jdoc) LOOP
    field_name := jdoc_keys.json_object_keys;
    spec := i_jdoc->field_name;

    -- for each field name, loop over the constrant ops
    FOR spec_keys IN SELECT * FROM json_object_keys(spec) LOOP
      op := spec_keys.json_object_keys;
      CASE op
      WHEN '$required' THEN
        target_constraint := format(
          'bqcn:%s:required',
          field_name);
        IF bq_constraint_name_exists(i_coll, target_constraint)
        THEN
          EXECUTE format(
            'alter table %I
            drop constraint "%s";',
            i_coll,
            target_constraint
          );
          result := true;
        END IF;

      WHEN '$notnull' THEN
        target_constraint := format(
          'bqcn:%s:notnull',
          field_name);
        IF bq_constraint_name_exists(i_coll, target_constraint)
        THEN
          EXECUTE format(
            'alter table %I
            drop constraint "%s";',
            i_coll,
            target_constraint
          );
          result := true;
        END IF;

      WHEN '$type' THEN
        s_type := spec->>op;
        target_constraint := format(
          'bqcn:%s:type:%s',
          field_name, s_type);
        IF bq_constraint_name_exists(i_coll, target_constraint)
        THEN
          EXECUTE format(
            'alter table %I
            drop constraint "%s";',
            i_coll,
            target_constraint
          );
          result := true;
        END IF;
      END CASE;

    END LOOP;
  END LOOP;

  RETURN result;
END
$$ LANGUAGE plpgsql;


/* Get a list of text descriptions of constraints on this collection.
 */
CREATE OR REPLACE FUNCTION bq_list_constraints(i_coll text)
RETURNS setof text AS $$
BEGIN
RETURN QUERY SELECT
  substring(constraint_name from 6)::text
  FROM information_schema.constraint_column_usage
  WHERE table_name = i_coll
  AND constraint_name LIKE 'bqcn:%'
  order by 1;
END
$$ LANGUAGE plpgsql;
-- # -- # -- # -- # -- #
-- Collection-level operations
-- # -- # -- # -- # -- #


/* Create a collection with the specified name
 */
CREATE OR REPLACE FUNCTION bq_create_collection(i_coll text)
RETURNS BOOLEAN AS $$
BEGIN
IF NOT (SELECT bq_collection_exists(i_coll))
THEN
    EXECUTE format('
    CREATE TABLE IF NOT EXISTS %1$I (
        _id varchar(256) PRIMARY KEY NOT NULL,
        bq_jdoc jsonb NOT NULL,
        created timestamptz default current_timestamp,
        updated timestamptz default current_timestamp,
        CONSTRAINT validate_id CHECK ((bq_jdoc->>''_id'') IS NOT NULL)
    );
    CREATE INDEX idx_%1$I_bq_jdoc ON %1$I USING gin (bq_jdoc);
    CREATE UNIQUE INDEX idx_%1$I_bq_jdoc_id ON %1$I ((bq_jdoc->>''_id''));
    ', i_coll);
    RETURN true;
ELSE
    RETURN false;
END IF;
END
$$ LANGUAGE plpgsql SECURITY DEFINER;


/* Get a list of existing collections.
 * This checks information_schema for tables matching the expected structure.
 */
CREATE OR REPLACE FUNCTION bq_list_collections()
RETURNS table(collection_name text) AS $$
BEGIN
RETURN QUERY SELECT table_name::text
       FROM information_schema.columns
       WHERE column_name = 'bq_jdoc'
       AND data_type = 'jsonb';
END
$$ LANGUAGE plpgsql SECURITY DEFINER;


/* Delete/drop a collection.
 * At the moment, this just drops whatever table matches the collection name.
 */
CREATE OR REPLACE FUNCTION bq_delete_collection(i_coll text)
RETURNS BOOLEAN AS $$
BEGIN
IF (SELECT bq_collection_exists(i_coll))
THEN
    EXECUTE format('DROP TABLE %I CASCADE;', i_coll);
    RETURN true;
ELSE
    RETURN false;
END IF;
END
$$ LANGUAGE plpgsql SECURITY DEFINER;
-- # -- # -- # -- # -- #
-- Document Reads
-- # -- # -- # -- # -- #


/* find one
 */
CREATE OR REPLACE FUNCTION bq_find_one(i_coll text, i_json_query json)
RETURNS table(bq_jdoc json) AS $$
BEGIN
IF (SELECT bq_collection_exists(i_coll))
THEN
    RETURN QUERY EXECUTE format(
        'SELECT bq_jdoc::json FROM %I
        WHERE bq_jdoc @> (%s)::jsonb
        LIMIT 1',
        i_coll,
        quote_literal(i_json_query)
    );
END IF;
END
$$ LANGUAGE plpgsql;


-- find one by id
CREATE OR REPLACE FUNCTION bq_find_one_by_id(i_coll text, i_id text)
RETURNS table(bq_jdoc json) AS $$
BEGIN
IF (SELECT bq_collection_exists(i_coll))
THEN
    RETURN QUERY EXECUTE format(
        'SELECT bq_jdoc::json FROM %I
        WHERE _id = %s
        LIMIT 1',
        i_coll,
        quote_literal(i_id)
    );
END IF;
END
$$ LANGUAGE plpgsql;

-- find many by ids
CREATE OR REPLACE FUNCTION bq_find_many_by_ids(i_coll text, i_ids jsonb)
RETURNS table(bq_jdoc json) AS $$
BEGIN
  IF (SELECT bq_collection_exists(i_coll))
  THEN
    IF jsonb_typeof(i_ids) != 'array'
    THEN
      RAISE EXCEPTION
      'Invalid ids parameter "%s"', json_typeof(i_ids)
      USING HINT = 'ids should be a json array of strings';
    END IF;
    RETURN QUERY EXECUTE format(
      'SELECT bq_jdoc::json FROM %I
      WHERE _id = ANY(array(select jsonb_array_elements_text(''%s''::jsonb)))
      ORDER BY created ASC;',
      i_coll,
      i_ids
    );
  END IF;
END
$$ LANGUAGE plpgsql;


/* find many documents
 */
CREATE OR REPLACE FUNCTION bq_find(i_coll text, i_json_query json, i_skip integer DEFAULT 0, i_limit integer DEFAULT null, i_sort json DEFAULT null)
RETURNS table(bq_jdoc json) AS $$
DECLARE
  q text = format('select bq_jdoc::json from %I where 1=1', i_coll);
BEGIN
IF (SELECT bq_collection_exists(i_coll))
THEN
    IF json_typeof(i_sort) != 'array'
    THEN
      RAISE EXCEPTION
      'Invalid sort parameter json type "%s"', json_typeof(i_sort)
      USING HINT = 'The i_sort parameter to bq_find should be a json array';
    END IF;
    -- query match
    q := q || format(' and bq_jdoc @> (%s)::jsonb ',
                     quote_literal(i_json_query));
    -- sort
    IF (i_sort IS NOT NULL)
    THEN
      q := q || format(' %s ', bq_sort_to_text(i_sort));
    END IF;
    -- skip and limit
    IF (i_limit IS NOT NULL)
    THEN
      q := q || format(' limit %s ', i_limit);
    ELSE
      q := q || format(' limit NULL ');
    END IF;
    -- final query
    q := q || format(' offset %s ', i_skip);
    RETURN QUERY EXECUTE q;
END IF;
END
$$ LANGUAGE plpgsql;


/* count documents in collection
 */
CREATE OR REPLACE FUNCTION bq_count(i_coll text, i_doc json)
RETURNS integer AS $$
DECLARE
  o_value int;
BEGIN
IF (SELECT bq_collection_exists(i_coll))
THEN
  EXECUTE format(
    'SELECT COUNT(_id) from %I
    WHERE bq_jdoc @> (%s)::jsonb',
     i_coll,
     quote_literal(i_doc)
  ) INTO o_value;
  RETURN o_value;
ELSE
  return 0;
END IF;
END
$$ LANGUAGE plpgsql;


/* Get a sequence of the distinct values present in the collection for a given key,
 * example: bq_distinct('people', 'address.city')
 */
CREATE OR REPLACE FUNCTION bq_distinct(i_coll text, i_key_path text)
RETURNS table(val jsonb) AS $$
DECLARE
  path_array text[];
BEGIN
  path_array := regexp_split_to_array(i_key_path, '\.');
  IF (SELECT bq_collection_exists(i_coll))
  THEN
    RETURN QUERY EXECUTE format(
      'select distinct (bq_jdoc#>''%s'')::jsonb as val from %I',
      path_array, i_coll
    );
  END IF;
END
$$ LANGUAGE plpgsql;
-- # -- # -- # -- # -- #
-- Document Writes
-- # -- # -- # -- # -- #


/* insert document
 */
CREATE OR REPLACE FUNCTION bq_insert(i_coll text, i_jdoc json)
RETURNS text AS $$
DECLARE
  doc json;
BEGIN
PERFORM bq_create_collection(i_coll);
IF (select i_jdoc->'_id') is null
THEN
  select bq_doc_set_key(i_jdoc, '_id', (select bq_generate_id())) into doc;
ELSE
  PERFORM bq_check_id_type(i_jdoc);
  doc := i_jdoc;
END IF;
EXECUTE format(
    'INSERT INTO %I (_id, bq_jdoc) VALUES (%s, %s);',
    i_coll,
    quote_literal(doc->>'_id'),
    quote_literal(doc)
);
return doc->>'_id';
END
$$ LANGUAGE plpgsql;


/* remove documents
 */
CREATE OR REPLACE FUNCTION bq_remove(i_coll text, i_jdoc json)
RETURNS setof integer AS $$
BEGIN
IF (SELECT bq_collection_exists(i_coll))
THEN
    RETURN QUERY EXECUTE format('
    WITH
      deleted AS
      (DELETE FROM %I WHERE bq_jdoc @> (%s)::jsonb RETURNING _id)
    SELECT count(*)::integer FROM deleted
    ', i_coll, quote_literal(i_jdoc));

ELSE
    RETURN QUERY SELECT 0;
END IF;
END
$$ LANGUAGE plpgsql;


/* remove one document
 */
CREATE OR REPLACE FUNCTION bq_remove_one(i_coll text, i_jdoc json)
RETURNS setof integer AS $$
BEGIN
IF (SELECT bq_collection_exists(i_coll))
THEN
    RETURN QUERY EXECUTE format('
      WITH
        candidates AS
        (SELECT _id from %1$I WHERE bq_jdoc @> (%2s)::jsonb LIMIT 1),
        deleted AS
        (DELETE FROM %1$I WHERE _id IN (select _id from candidates) RETURNING _id)
      SELECT count(*)::integer FROM deleted
    ', i_coll, quote_literal(i_jdoc));
ELSE
    RETURN QUERY SELECT 0;
END IF;
END
$$ LANGUAGE plpgsql;


/* remove one document
 */
CREATE OR REPLACE FUNCTION bq_remove_one_by_id(i_coll text, i_id text)
RETURNS setof integer AS $$
BEGIN
IF (SELECT bq_collection_exists(i_coll))
THEN
    RETURN QUERY EXECUTE format('
    WITH
    deleted AS
    (DELETE FROM %1$I WHERE _id = %2$s RETURNING _id)
    SELECT count(*)::integer FROM deleted
    ', i_coll, quote_literal(i_id));
ELSE
RETURN QUERY SELECT 0;
END IF;
END
$$ LANGUAGE plpgsql;


/* save document
 */
CREATE OR REPLACE FUNCTION bq_save(i_coll text, i_jdoc json)
RETURNS text AS $$
DECLARE
  o_id text;
  existing_id_count integer;
BEGIN
  SELECT bq_insert(i_coll, i_jdoc) INTO o_id;
  RETURN o_id;
EXCEPTION WHEN unique_violation THEN
  EXECUTE format('
    UPDATE %I SET bq_jdoc = %s::jsonb WHERE _id = %s returning _id',
    i_coll,
    quote_literal(i_jdoc),
    quote_literal(i_jdoc->>'_id')) INTO o_id;
  RETURN o_id;
END
$$ LANGUAGE plpgsql;
-- # -- # -- # -- # -- #
-- Utilities
-- # -- # -- # -- # -- #


/* Generate a random string ID.
 * Used by the document write functions to populate the '_id' field
 * if it is missing.
 */
CREATE OR REPLACE FUNCTION bq_generate_id ()
RETURNS char(24) AS $$
BEGIN
RETURN CAST(encode(gen_random_bytes(12), 'hex') as char(24));
END
$$ LANGUAGE plpgsql;


/* private - Set a key in a json document.
 */
CREATE OR REPLACE FUNCTION bq_doc_set_key(i_jdoc json, i_key text, i_val anyelement)
RETURNS json AS $$
BEGIN
RETURN (
  SELECT concat(
      '{',
      string_agg(to_json("key")
        || ':'
        || "value", ','),
      '}'
    )::json
  FROM (SELECT *
  FROM json_each(i_jdoc)
  WHERE key <> i_key
  UNION ALL
  SELECT i_key, to_json(i_val)) as "fields")::json;
END
$$ LANGUAGE plpgsql;


/* Check if a collection exists.
 * Currently does a simple check for a table with the specified name.
 */
CREATE OR REPLACE FUNCTION bq_collection_exists (i_coll text)
RETURNS boolean AS $$
BEGIN
RETURN EXISTS (
    SELECT relname FROM pg_class WHERE relname = format('%s', i_coll)
);
END
$$ LANGUAGE plpgsql;


/* private - Ensure the _id field of the supplied json document
 * is a string value.
 * If it's not, an exception is raised. Ideally, the client should validate
 * this is the case before submitting to the server.
 */
CREATE OR REPLACE FUNCTION bq_check_id_type(i_jdoc json)
RETURNS VOID AS $$
BEGIN
  IF (SELECT json_typeof(i_jdoc->'_id')) <> 'string'
  THEN
    RAISE EXCEPTION 'The _id field is not a string: % ', i_jdoc->'_id'
    USING HINT = 'The _id field must be a string';
  END IF;
END
$$ LANGUAGE plpgsql;


/* private - Check if a dotted path exists in a document
 */
CREATE OR REPLACE FUNCTION bq_path_exists(i_path text, i_jdoc jsonb)
RETURNS boolean AS $$
DECLARE
  path_array text[];
  depth int;
  path_key text;
  current_object jsonb;
BEGIN
  current_object := i_jdoc;
  IF i_path = '' THEN
    RETURN false;
  END IF;
  IF i_path NOT LIKE '%.%' THEN
    RETURN (current_object ? i_path);
  END IF;

  path_array := regexp_split_to_array(i_path, '\.');
  FOREACH path_key IN ARRAY path_array LOOP
    IF jsonb_typeof(current_object) = 'object' THEN
      IF current_object ? path_key THEN
        current_object := current_object->path_key;
      ELSE
        RETURN false;
      END IF;
    ELSIF jsonb_typeof(current_object) = 'array' THEN
      IF path_key ~ '^\d+$' THEN
        current_object := current_object->path_key::int;
      ELSE
        RETURN false;
      END IF;
    ELSE
      RETURN false;
    END IF;
  END LOOP;
  RETURN true;

END
$$ language plpgsql;


/* private - transform a json sort spec into an 'ORDER BY...' string
 */
CREATE OR REPLACE FUNCTION bq_sort_to_text(i_sort json)
RETURNS text AS $$
DECLARE
  sort_spec json;
  pair RECORD;
  dotted_path text;
  path_array text[];
  direction text = 'ASC';
  o_query text;
BEGIN
  o_query := 'order by ';
  for sort_spec in select value from json_array_elements(i_sort) loop
    for pair in select * from json_each(sort_spec) limit 1 loop
      dotted_path := pair.key;
      if (pair.value::text = '-1')
      then
        direction := 'DESC';
      elsif (pair.value::text = '1')
      then
        direction := 'ASC';
      else
        raise exception 'Invalid sort direction "%s"', pair.value::text
        using hint = 'sort direction must be either 1 (ascending) or -1 (descending)';
      end if;
      path_array := regexp_split_to_array(dotted_path, '\.');
      o_query := o_query || format(' bq_jdoc#>''%s'' %s, ', path_array, direction);
    end loop;
  end loop;
  o_query := o_query || ' updated ';
  return o_query;
END
$$ LANGUAGE plpgsql;


/* private - raise an exception if the extension version is less than
 * the supplied version.
 */
CREATE OR REPLACE FUNCTION bq_assert_minimum_version(i_version text)
RETURNS boolean AS $$
DECLARE
  version text;
BEGIN
  select extversion from pg_catalog.pg_extension
  where extname = 'bedquilt'
  into version;
  if version = 'HEAD' then
    return true;
  end if;
  if version < i_version then
    raise exception
    'Bedquilt extension version (%) less than %', version, i_version
    using hint = 'Update the bedquilt extension to a newer version';
  end if;
  return true;
END
$$ LANGUAGE plpgsql;
