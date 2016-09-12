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
 * Example:
 *   select bq_add_constraints('things', '{"name": {"$required": true}}')
 */
CREATE OR REPLACE FUNCTION bq_add_constraints(i_coll text, i_jdoc jsonb)
RETURNS boolean AS $$
DECLARE
  jdoc_keys RECORD;
  field_name text;
  spec jsonb;
  spec_keys RECORD;
  op text;
  new_constraint_name text;
  s_type text;
  result boolean;
BEGIN
  result := false;
  -- loop over the field names
  FOR jdoc_keys IN SELECT * FROM jsonb_object_keys(i_jdoc) LOOP
    field_name := jdoc_keys.jsonb_object_keys;
    spec := i_jdoc->field_name;

    -- for each field name, loop over the constrant ops
    FOR spec_keys IN SELECT * FROM jsonb_object_keys(spec) LOOP
      op := spec_keys.jsonb_object_keys;
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
              add constraint %s
              check (bq_util_path_exists(%s, bq_jdoc));',
              i_coll,
              quote_ident(new_constraint_name),
              quote_literal(field_name));
            result := true;
          ELSE
            EXECUTE format(
              'alter table %I
              add constraint %s
              check (bq_jdoc ? %s);',
              i_coll,
              quote_ident(new_constraint_name),
              quote_literal(field_name));
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
            add constraint %s
            check (
              jsonb_typeof((bq_jdoc#>%s)::jsonb) <> ''null''
            );',
            i_coll,
            quote_ident(new_constraint_name),
            quote_literal(regexp_split_to_array(field_name, '\.')));
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
            add constraint %s
            check (
              jsonb_typeof(bq_jdoc#>%s) in (%s, ''null'')
            );',
            quote_ident(i_coll),
            quote_ident(new_constraint_name),
            quote_literal(regexp_split_to_array(field_name, '\.')),
            quote_literal(s_type));
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
 * Example:
 *   select bq_remove_constraints('things', '{"name": {"$required": true}}')
 */
CREATE OR REPLACE FUNCTION bq_remove_constraints(i_coll text, i_jdoc jsonb)
RETURNS boolean AS $$
DECLARE
  jdoc_keys RECORD;
  field_name text;
  spec jsonb;
  spec_keys RECORD;
  op text;
  target_constraint text;
  s_type text;
  result boolean;
BEGIN

  result := false;
  -- loop over the field names
  FOR jdoc_keys IN SELECT * FROM jsonb_object_keys(i_jdoc) LOOP
    field_name := jdoc_keys.jsonb_object_keys;
    spec := i_jdoc->field_name;

    -- for each field name, loop over the constrant ops
    FOR spec_keys IN SELECT * FROM jsonb_object_keys(spec) LOOP
      op := spec_keys.jsonb_object_keys;
      CASE op
      WHEN '$required' THEN
        target_constraint := format(
          'bqcn:%s:required',
          field_name);
        IF bq_constraint_name_exists(i_coll, target_constraint)
        THEN
          EXECUTE format(
            'alter table %I
            drop constraint %s;',
            quote_ident(i_coll),
            quote_ident(target_constraint)
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
            drop constraint %s;',
            quote_ident(i_coll),
            quote_ident(target_constraint)
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
            drop constraint %s;',
            quote_ident(i_coll),
            quote_ident(target_constraint)
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
 * Example:
 *   select bq_list_constraints('orders')
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


/* Create a collection with the specified name.
 * Example:
 *   select bq_create_collection('orders');
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
    ', quote_ident(i_coll));
    RETURN true;
ELSE
    RETURN false;
END IF;
END
$$ LANGUAGE plpgsql;


/* Get a list of existing collections.
 * This checks information_schema for tables matching the expected structure.
 * Example:
 *   select bq_list_collections();
 */
CREATE OR REPLACE FUNCTION bq_list_collections()
RETURNS table(collection_name text) AS $$
BEGIN
RETURN QUERY SELECT table_name::text
       FROM information_schema.columns
       WHERE column_name = 'bq_jdoc'
       AND data_type = 'jsonb';
END
$$ LANGUAGE plpgsql;


/* Delete/drop a collection.
 * At the moment, this just drops whatever table matches the collection name.
 * Example:
 *   select bq_delete_collection('orders');
 */
CREATE OR REPLACE FUNCTION bq_delete_collection(i_coll text)
RETURNS BOOLEAN AS $$
BEGIN
IF (SELECT bq_collection_exists(i_coll))
THEN
    EXECUTE format('DROP TABLE %I CASCADE;', quote_ident(i_coll));
    RETURN true;
ELSE
    RETURN false;
END IF;
END
$$ LANGUAGE plpgsql;


/* Check if a collection exists.
 * Example:
 *   select bq_collection_exists('orders');
 */
CREATE OR REPLACE FUNCTION bq_collection_exists (i_coll text)
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT table_name FROM information_schema.columns
    where table_name = i_coll and column_name = 'bq_jdoc'
  );
END
$$ LANGUAGE plpgsql;
-- # -- # -- # -- # -- #
-- Document Reads
-- # -- # -- # -- # -- #


/* Find one document from a collection, matching a query document.
 * Effectively the same as bq_find with limit set to 1.
 * Params:
 *   - i_coll: collection name
 *   - i_json_query: the query document
 *   - i_skip: (optional) number of documents to skip, default 0
 *   - i_sort: (optional) json array of sort specifications, default null
 * Example:
 *   select bq_find_one('orders', '{"processed": false}');
 */
CREATE OR REPLACE FUNCTION bq_find_one(i_coll text, i_json_query jsonb, i_skip integer DEFAULT 0, i_sort jsonb DEFAULT null)
RETURNS table(bq_jdoc jsonb) AS $$
DECLARE
  q text;
  mq text;
  sq text[];
  s text;
BEGIN
  IF (SELECT bq_collection_exists(i_coll))
  THEN
    -- base query
    q := format('SELECT bq_jdoc::jsonb FROM %I', quote_ident(i_coll));
    -- split json query doc into match query and special queries
    SELECT match_query, special_queries
      FROM bq_util_split_queries(i_json_query::jsonb)
      INTO mq, sq;
    q := q || format(' WHERE bq_jdoc @> (%s)::jsonb ', quote_literal(mq));
    IF array_length(sq, 1) > 0
    THEN
      FOREACH s IN ARRAY sq
      LOOP
        q := q || format(' AND %s ', s);
      END LOOP;
    END IF;
    -- sort
    IF (i_sort IS NOT NULL)
    THEN
      q := q || format(' %s ', bq_util_sort_to_text(i_sort));
    END IF;
    -- skip
    q := q || format(' offset %s ', i_skip);
    -- final query
    q := q || ' limit 1 ';
    RETURN QUERY EXECUTE q;
  END IF;
END
$$ LANGUAGE plpgsql;


/* Find a single document from a collection, by it's `_id` property.
 * This function is potentially faster than the equivalent call to bq_find_one
 * with a '{"_id": "..."}' query document.
 * Example:
 *   select bq_find_one_by_id('things', 'fa0c852e4bc5d384b5f9fde5');
 */
CREATE OR REPLACE FUNCTION bq_find_one_by_id(i_coll text, i_id text)
RETURNS table(bq_jdoc jsonb) AS $$
BEGIN
IF (SELECT bq_collection_exists(i_coll))
  THEN
    RETURN QUERY EXECUTE format(
      'SELECT bq_jdoc::jsonb FROM %I
      WHERE _id = %s
      LIMIT 1',
      quote_ident(i_coll),
      quote_literal(i_id)
    );
  END IF;
END
$$ LANGUAGE plpgsql;

/* Find many documents by their `_id` fields.
 * Example:
 *   select bq_find_many_by_ids('things', '["one", "four", "nine"]');
 */
CREATE OR REPLACE FUNCTION bq_find_many_by_ids(i_coll text, i_ids jsonb)
RETURNS table(bq_jdoc jsonb) AS $$
BEGIN
  IF (SELECT bq_collection_exists(i_coll))
  THEN
    IF jsonb_typeof(i_ids) != 'array'
    THEN
      RAISE EXCEPTION
      'Invalid ids parameter "%s"', jsonb_typeof(i_ids)
      USING HINT = 'ids should be a json array of strings';
    END IF;
    RETURN QUERY EXECUTE format(
      'SELECT bq_jdoc::jsonb FROM %I
      WHERE _id = ANY(array(select jsonb_array_elements_text(%s::jsonb)))
      ORDER BY created ASC;',
      quote_ident(i_coll),
      quote_literal(i_ids)
    );
  END IF;
END
$$ LANGUAGE plpgsql;


/* Find documents from a collection, matching a query document.
 * Params:
 *   - i_coll: collection name
 *   - i_json_query: the query document
 *   - i_skip: (optional) number of documents to skip, default 0
 *   - i_limit: (optional) number of documents to limit the result set to,
       default null, returns all documents matching
 *   - i_sort: (optional) json array of sort specifications, default null
 * Example:
 *   select bq_find('orders', '{"processed": false}');
 *   select bq_find('orders', '{"processed": false}', 2, 10, '[{"orderTime": -1}]');
 */
CREATE OR REPLACE FUNCTION bq_find(i_coll text, i_json_query jsonb, i_skip integer DEFAULT 0, i_limit integer DEFAULT null, i_sort jsonb DEFAULT null)
RETURNS table(bq_jdoc jsonb) AS $$
DECLARE
  q text = format('select bq_jdoc::jsonb from %I ', quote_ident(i_coll));
  mq text;
  sq text[];
  s text;
BEGIN
  IF (SELECT bq_collection_exists(i_coll))
  THEN
    IF jsonb_typeof(i_sort) != 'array'
    THEN
      RAISE EXCEPTION
      'Invalid sort parameter json type "%s"', jsonb_typeof(i_sort)
      USING HINT = 'The i_sort parameter to bq_find should be a json array';
    END IF;
    -- query match
    SELECT match_query, special_queries
      FROM bq_util_split_queries(i_json_query::jsonb)
      INTO mq, sq;
    q := q || format(' WHERE bq_jdoc @> (%s)::jsonb ', quote_literal(mq));
    -- special queries
    IF array_length(sq, 1) > 0
    THEN
      FOREACH s IN ARRAY sq
      LOOP
        q := q || format(' AND %s ', s);
      END LOOP;
    END IF;
    -- sort
    IF (i_sort IS NOT NULL)
    THEN
      q := q || bq_util_sort_to_text(i_sort);
    END IF;
    -- skip and limit
    IF (i_limit IS NOT NULL)
    THEN
      q := q || format(' LIMIT %s::integer ', quote_literal(i_limit));
    END IF;
    q := q || format(' offset %s::integer ', quote_literal(i_skip));
    -- final query
    RETURN QUERY EXECUTE q;
  END IF;
END
$$ LANGUAGE plpgsql;


/* Count documents in a collection, matching a query document.
 * Example:
 *   select bq_countt('orders', '{"processed": true}')
 */
CREATE OR REPLACE FUNCTION bq_count(i_coll text, i_doc jsonb)
RETURNS integer AS $$
DECLARE
  o_value int;
BEGIN
IF (SELECT bq_collection_exists(i_coll))
THEN
  EXECUTE format(
    'SELECT COUNT(_id) from %I
    WHERE bq_jdoc @> (%s)::jsonb',
     quote_ident(i_coll),
     quote_literal(i_doc)
  ) INTO o_value;
  RETURN o_value;
ELSE
  return 0;
END IF;
END
$$ LANGUAGE plpgsql;


/* Get a sequence of the distinct values present in the collection for a given key,
 * Example:
 *   select bq_distinct('people', 'address.city')
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
      'select distinct (bq_jdoc#>%s)::jsonb as val from %I',
      quote_literal(path_array), quote_ident(i_coll)
    );
  END IF;
END
$$ LANGUAGE plpgsql;
-- # -- # -- # -- # -- #
-- Document Writes
-- # -- # -- # -- # -- #


/* Insert a document into a collection.
 * Raises an error if a document already exists with the same `_id` field.
 * If the document doesn't contain an `_id` field, then one will be randomly generated
 * Example:
 *   select bq_insert('things', '{"name": "wrench"}');
 */
CREATE OR REPLACE FUNCTION bq_insert(i_coll text, i_jdoc jsonb)
RETURNS text AS $$
DECLARE
  doc jsonb;
BEGIN
  PERFORM bq_create_collection(i_coll);
  IF (select i_jdoc->'_id') is null
  THEN
    select i_jdoc::jsonb || format('{"_id": "%s"}', bq_util_generate_id())::jsonb into doc;
  ELSE
    IF (SELECT jsonb_typeof(i_jdoc->'_id')) <> 'string'
    THEN
      RAISE EXCEPTION 'The _id field is not a string: % ', i_jdoc->'_id'
      USING HINT = 'The _id field must be a string';
    END IF;
    doc := i_jdoc;
  END IF;
  EXECUTE format(
      'INSERT INTO %I (_id, bq_jdoc) VALUES (%s, %s);',
      quote_ident(i_coll),
      quote_literal(doc->>'_id'),
      quote_literal(doc)
  );
  return doc->>'_id';
END
$$ LANGUAGE plpgsql;


/* Remove documents from a collection, matching a query document.
 * Returns count of deleted documents.
 * Example:
 *   select bq_remove('orders', '{"cancelled": true}');
 */
CREATE OR REPLACE FUNCTION bq_remove(i_coll text, i_jdoc jsonb)
RETURNS setof integer AS $$
BEGIN
IF (SELECT bq_collection_exists(i_coll))
THEN
    RETURN QUERY EXECUTE format('
    WITH
      deleted AS
      (DELETE FROM %I WHERE bq_jdoc @> (%s)::jsonb RETURNING _id)
    SELECT count(*)::integer FROM deleted
    ', quote_ident(i_coll), quote_literal(i_jdoc));

ELSE
    RETURN QUERY SELECT 0;
END IF;
END
$$ LANGUAGE plpgsql;


/* Remove a single document from a collection, matching a query document.
 * The first document to match the query will be removed.
 * Returns count of deleted documents, either one or zero.
 * Example:
 *   select bq_remove_one('orders', '{"cancelled": true}');
 */
CREATE OR REPLACE FUNCTION bq_remove_one(i_coll text, i_jdoc jsonb)
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
    ', quote_ident(i_coll), quote_literal(i_jdoc));
ELSE
    RETURN QUERY SELECT 0;
END IF;
END
$$ LANGUAGE plpgsql;


/* Remove a single document from a collection, by its `_id` field.
 * Returns count of deleted documents, either one or zero.
 * Example:
 *   select bq_remove_one_by_id('orders', '4d733fb148e7d89f7c569655');
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
    ', quote_ident(i_coll), quote_literal(i_id));
ELSE
RETURN QUERY SELECT 0;
END IF;
END
$$ LANGUAGE plpgsql;


/* Remove many documents, by their `_id` fields.
* Returns count of deleted documents, either one or zero.
* Example:
*   select bq_remove_one_by_id('orders', '4d733fb148e7d89f7c569655');
*/
CREATE OR REPLACE FUNCTION bq_remove_many_by_ids(i_coll text, i_ids jsonb)
RETURNS setof integer AS $$
BEGIN
  IF (SELECT bq_collection_exists(i_coll))
  THEN
    IF jsonb_typeof(i_ids) != 'array'
    THEN
      RAISE EXCEPTION
      'Invalid ids parameter "%s"', jsonb_typeof(i_ids)
      USING HINT = 'ids should be a json array of strings';
    END IF;
    RETURN QUERY EXECUTE format('
      WITH
      deleted AS
      (DELETE FROM %1$I WHERE _id = ANY(select jsonb_array_elements_text(%2$s::jsonb)) RETURNING _id)
      SELECT count(*)::integer FROM deleted',
      quote_ident(i_coll),
      quote_literal(i_ids)
     );
  ELSE
    RETURN QUERY SELECT 0;
  END IF;
END
$$ LANGUAGE plpgsql;



/* Save a document to a collection.
 * Similar to `bq_insert`, but will overwrite an existing document if one with a matching
 * `_id` field is found. Can be used to either create new documents or update existing documents.
 * Example:
 *   select bq_save('things', '{"_id": "abc", "name": "wrench"}');
 */
CREATE OR REPLACE FUNCTION bq_save(i_coll text, i_jdoc jsonb)
RETURNS text AS $$
DECLARE
  o_id text;
  existing_id_count integer;
BEGIN
  SELECT bq_insert(i_coll, i_jdoc) INTO o_id;
  RETURN o_id;
EXCEPTION WHEN unique_violation THEN
  EXECUTE format('
    UPDATE %I SET bq_jdoc = %s::jsonb, updated = now() WHERE _id = %s returning _id',
    quote_ident(i_coll),
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
CREATE OR REPLACE FUNCTION bq_util_generate_id ()
RETURNS char(24) AS $$
BEGIN
RETURN CAST(encode(gen_random_bytes(12), 'hex') as char(24));
END
$$ LANGUAGE plpgsql;


/* private - Check if a dotted path exists in a document
 */
CREATE OR REPLACE FUNCTION bq_util_path_exists(i_path text, i_jdoc jsonb)
RETURNS boolean AS $$
DECLARE
  path_array text[];
BEGIN
  path_array := regexp_split_to_array(i_path, '\.');
  return i_jdoc #> path_array is not null;
END
$$ language plpgsql;


/* private - transform a json sort spec into an 'ORDER BY...' string
 */
CREATE OR REPLACE FUNCTION bq_util_sort_to_text(i_sort jsonb)
RETURNS text AS $$
DECLARE
  sort_spec jsonb;
  pair RECORD;
  dotted_path text;
  path_array text[];
  direction text = 'ASC';
  o_query text;
BEGIN
  o_query := 'order by ';
  for sort_spec in select value from jsonb_array_elements(i_sort) loop
    for pair in select * from jsonb_each(sort_spec) limit 1 loop
      dotted_path := pair.key;
      if (pair.value::text = '-1') then
        direction := 'DESC';
      elsif (pair.value::text = '1') then
        direction := 'ASC';
      else
        raise exception 'Invalid sort direction "%s"', pair.value::text
        using hint = 'sort direction must be either 1 (ascending) or -1 (descending)';
      end if;
      if pair.key = '$created' then
        o_query := o_query || format(' created %s, ', direction);
      elsif pair.key = '$updated' then
        o_query := o_query || format(' updated %s, ', direction);
      else
        path_array := regexp_split_to_array(dotted_path, '\.');
        o_query := o_query || format(' bq_jdoc#>%s %s, ',
          quote_literal(path_array),
          direction
        );
      end if;
    end loop;
  end loop;
  o_query := o_query || ' updated ';
  return o_query;
END
$$ LANGUAGE plpgsql;


/* private - raise an exception if the extension version is less than
 * the supplied version.
 */
CREATE OR REPLACE FUNCTION bq_util_assert_minimum_version(i_version text)
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


DROP TYPE IF EXISTS bq_util_split_queries_result;



/* private - return type for bq_split_queries
*/
CREATE TYPE bq_util_split_queries_result AS (
    match_query text,
    special_queries text[]
);


/* private - split a json query into query and special queries, '$eq' etc.
 */
CREATE OR REPLACE FUNCTION bq_util_split_queries(i_json jsonb)
  RETURNS bq_util_split_queries_result
AS $$
  if 'json' in SD:
    json = SD['json']
  else:
    import json
    SD['json'] = json

  data = json.loads(i_json)
  special_queries = []
  def proc(d, current_path):
    keys = d.keys()
    deletions = []
    for k in keys:
      v = d[k]
      if k.startswith('$'):
        if k == '$eq':
          s = "bq_jdoc #> {} = {}::jsonb".format(
            plpy.quote_literal("{{{}}}".format(",".join(current_path))),
            plpy.quote_literal(json.dumps(v))
          ).strip()

        elif k == '$noteq':
          s = "(bq_jdoc #> {} != {}::jsonb or bq_jdoc #> {} is null)".format(
            plpy.quote_literal("{{{}}}".format(",".join(current_path))),
            plpy.quote_literal(json.dumps(v)),
            plpy.quote_literal("{{{}}}".format(",".join(current_path)))
          ).strip()

        elif k == '$gte':
          s = "bq_jdoc #> {} >= {}::jsonb".format(
            plpy.quote_literal("{{{}}}".format(",".join(current_path))),
            plpy.quote_literal(json.dumps(v))
          ).strip()

        elif k == '$gt':
          s = "bq_jdoc #> {} > {}::jsonb".format(
            plpy.quote_literal("{{{}}}".format(",".join(current_path))),
            plpy.quote_literal(json.dumps(v))
          ).strip()

        elif k == '$lte':
          s = "bq_jdoc #> {} <= {}::jsonb".format(
            plpy.quote_literal("{{{}}}".format(",".join(current_path))),
            plpy.quote_literal(json.dumps(v))
          ).strip()

        elif k == '$lt':
          s = "bq_jdoc #> {} < {}::jsonb".format(
            plpy.quote_literal("{{{}}}".format(",".join(current_path))),
            plpy.quote_literal(json.dumps(v))
          ).strip()

        elif k == '$in':
          if type(v) is not list:
            plpy.error("Value of '$in' operator must be an array")
          s = "bq_jdoc #> {} <@ {}::jsonb".format(
            plpy.quote_literal("{{{}}}".format(",".join(current_path))),
            plpy.quote_literal(json.dumps(v))
          ).strip()

        elif k == '$notin':
          if type(v) is not list:
            plpy.error("Value of '$notin' operator must be an array")
          s = "(not (bq_jdoc #> {} <@ {}::jsonb))".format(
            plpy.quote_literal("{{{}}}".format(",".join(current_path))),
            plpy.quote_literal(json.dumps(v))
          ).strip()

        elif k == '$exists':
          if type(v) is not bool:
            plpy.error("Value of '$exists' operator must be a boolean")
          if v is True:
            s = "bq_jdoc #> {} is not null".format(
              plpy.quote_literal("{{{}}}".format(",".join(current_path))),
            ).strip()
          else:
            s = "bq_jdoc #> {} is null".format(
              plpy.quote_literal("{{{}}}".format(",".join(current_path))),
            ).strip()

        elif k == '$type':
          if type(v) is not str:
            plpy.error("Value of '$type' operator must be a string")
          s = "jsonb_typeof(bq_jdoc #> {}) = {}".format(
            plpy.quote_literal("{{{}}}".format(",".join(current_path))),
            plpy.quote_literal(v)
          ).strip()

        elif k == '$like':
          if type(v) is not str:
            plpy.error("Value of '$like' operator must be a string")
          s = "(jsonb_typeof(bq_jdoc#>{})='string' and bq_jdoc#>>{} like {})".format(
            plpy.quote_literal("{{{}}}".format(",".join(current_path))),
            plpy.quote_literal("{{{}}}".format(",".join(current_path))),
            plpy.quote_literal(v)
          ).strip()

        elif k == '$regex':
          if type(v) is not str:
            plpy.error("Value of '$regex' operator must be a string")
          s = "(jsonb_typeof(bq_jdoc#>{})='string' and bq_jdoc#>>{} ~ {})".format(
            plpy.quote_literal("{{{}}}".format(",".join(current_path))),
            plpy.quote_literal("{{{}}}".format(",".join(current_path))),
            plpy.quote_literal(v)
          ).strip()

        else:
          plpy.error("Invalid query operator: {}".format(k))
        special_queries.append(s)
        deletions.append(k)
      else:
        if type(v) == dict:
          p = list(current_path)
          p.extend([k])
          proc(v, p)
          if len(v.keys()) == 0:
            deletions.append(k)
    for s in deletions:
      del d[s]
  proc(data, [])
  return (json.dumps(data), special_queries)
$$ LANGUAGE plpython3u;
