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
