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
    -- query match
    q := q || format(' and bq_jdoc @> (%s)::jsonb ',
                     quote_literal(i_json_query));
    -- sort
    if (i_sort is not null)
    then
      q := q || format(' %s ', bq_sort_to_text(i_sort));
    end if;
    -- skip and limit
    IF (i_limit is not null)
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
