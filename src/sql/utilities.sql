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


/* private - Check if a dotted path exists in a document
 */
CREATE OR REPLACE FUNCTION bq_path_exists(i_path text, i_jdoc jsonb)
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


DROP TYPE IF EXISTS bq_split_queries_result;

/* private - return type for bq_split_queries
*/
CREATE TYPE bq_split_queries_result AS (
    match_query text,
    special_queries text[]
);


/* private - split a json query into query and special queries, '$eq' etc.
 */
CREATE OR REPLACE FUNCTION bq_split_queries(i_json jsonb)
  RETURNS bq_split_queries_result
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
