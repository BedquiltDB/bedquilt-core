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
