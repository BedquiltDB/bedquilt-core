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
              add constraint %s
              check (bq_path_exists(%s, bq_jdoc));',
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
