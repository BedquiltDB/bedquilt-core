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
    select i_jdoc::jsonb || format('{"_id": "%s"}', bq_generate_id())::jsonb into doc;
  ELSE
    IF (SELECT json_typeof(i_jdoc->'_id')) <> 'string'
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
    ', quote_ident(i_coll), quote_literal(i_jdoc));

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
    ', quote_ident(i_coll), quote_literal(i_jdoc));
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
    ', quote_ident(i_coll), quote_literal(i_id));
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
    UPDATE %I SET bq_jdoc = %s::jsonb, updated = now() WHERE _id = %s returning _id',
    quote_ident(i_coll),
    quote_literal(i_jdoc),
    quote_literal(i_jdoc->>'_id')) INTO o_id;
  RETURN o_id;
END
$$ LANGUAGE plpgsql;
