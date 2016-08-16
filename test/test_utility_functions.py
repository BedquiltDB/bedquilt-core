import testutils
import json
import psycopg2


class TestSplitQueries(testutils.BedquiltTestCase):

    def _assert_examples(self, examples):
        for query, match, specials in examples:
            result = self._query(
                """
                select * from bq_split_queries(%s::jsonb)
                """,
                (json.dumps(query),)
            )
            self.assertEqual(json.loads(result[0][0]), match)
            self.assertEqual(result[0][1], specials)

    def test_simple_queries_with_no_specials(self):

        examples = [
            ({'a': {'b': 1}},
             {'a': {'b': 1}},
             []),
            ({'a': 1, 'b': 2},
             {'a': 1, 'b': 2},
             [])
        ]

        self._assert_examples(examples)

    def test_advanced_queries(self):
        examples = [
            # $eq
            (
                {
                    'a': {
                        'b': {
                            '$eq': 22
                        }
                    }
                },
                {},
                ["bq_jdoc #> '{a,b}' = '22'::jsonb"]
            ),
            (
                {
                    'a': {
                        'b': {
                            '$eq': 22
                        }
                    },
                    'c': 44
                },
                {'c': 44},
                ["bq_jdoc #> '{a,b}' = '22'::jsonb"]
            ),
            (
                {
                    'a': {
                        'b': {
                            '$eq': 22
                        },
                        'c': 44
                    }
                },
                {'a': {'c': 44}},
                ["bq_jdoc #> '{a,b}' = '22'::jsonb"]
            ),
            # $noteq
            (
                {
                    'a': {
                        'b': {
                            '$noteq': 22
                        },
                        'c': 44
                    }
                },
                {'a': {'c': 44}},
                ["(bq_jdoc #> '{a,b}' != '22'::jsonb or bq_jdoc #> '{a,b}' is null)"]
            ),
            # $gte
            (
                {
                    'a': {
                        'b': {
                            '$gte': 22
                        },
                        'c': 44
                    }
                },
                {'a': {'c': 44}},
                ["bq_jdoc #> '{a,b}' >= '22'::jsonb"]
            ),
            # $gt
            (
                {
                    'a': {
                        'b': {
                            '$gt': 22
                        },
                        'c': 44
                    }
                },
                {'a': {'c': 44}},
                ["bq_jdoc #> '{a,b}' > '22'::jsonb"]
            ),
            # $lte
            (
                {
                    'a': {
                        'b': {
                            '$lte': 22
                        },
                        'c': 44
                    }
                },
                {'a': {'c': 44}},
                ["bq_jdoc #> '{a,b}' <= '22'::jsonb"]
            ),
            # $lt
            (
                {
                    'a': {
                        'b': {
                            '$lt': 22
                        },
                        'c': 44
                    }
                },
                {'a': {'c': 44}},
                ["bq_jdoc #> '{a,b}' < '22'::jsonb"]
            ),
            # $in
            (
                {
                    'a': {
                        'b': {
                            '$in': [22, 21]
                        },
                        'c': 44
                    }
                },
                {'a': {'c': 44}},
                ["bq_jdoc #> '{a,b}' <@ '[22, 21]'::jsonb"]
            ),
            # $notin
            (
                {
                    'a': {
                        'b': {
                            '$notin': [22, 21]
                        },
                        'c': 44
                    }
                },
                {'a': {'c': 44}},
                ["(not (bq_jdoc #> '{a,b}' <@ '[22, 21]'::jsonb))"]
            ),
            # $exists
            (
                {
                    'a': {
                        'b': {
                            '$exists': True
                        },
                        'c': 44
                    }
                },
                {'a': {'c': 44}},
                ["bq_jdoc #> '{a,b}' is not null"]
            ),
            (
                {
                    'a': {
                        'b': {
                            '$exists': False
                        },
                        'c': 44
                    }
                },
                {'a': {'c': 44}},
                ["bq_jdoc #> '{a,b}' is null"]
            ),
            # $type
            (
                {
                    'a': {
                        'b': {
                            '$type': 'number'
                        },
                        'c': 44
                    }
                },
                {'a': {'c': 44}},
                ["jsonb_typeof(bq_jdoc #> '{a,b}') = 'number'"]
            ),
            # $like
            (
                {
                    'a': {
                        'b': {
                            '$like': '%wat%'
                        },
                        'c': 44
                    }
                },
                {'a': {'c': 44}},
                ["(jsonb_typeof(bq_jdoc#>'{a,b}')='string' and bq_jdoc#>>'{a,b}' like '%wat%')"]
            ),
            # $regex
            (
                {
                    'a': {
                        'b': {
                            '$regex': '.*wat.*'
                        },
                        'c': 44
                    }
                },
                {'a': {'c': 44}},
                ["(jsonb_typeof(bq_jdoc#>'{a,b}')='string' and bq_jdoc#>>'{a,b}' ~ '.*wat.*')"]
            )
        ]

        self._assert_examples(examples)

    def test_supported_ops(self):
        examples = [
            (
                {'a': {'b': {'$eq': 42}}},
                {},
                ["bq_jdoc #> '{a,b}' = '42'::jsonb"]
            ),
            (
                {'a': {'b': {'$noteq': 42}}},
                {},
                ["(bq_jdoc #> '{a,b}' != '42'::jsonb or bq_jdoc #> '{a,b}' is null)"]
            ),
            (
                {'a': {'b': {'$gte': 42}}},
                {},
                ["bq_jdoc #> '{a,b}' >= '42'::jsonb"]
            ),
            (
                {'a': {'b': {'$gt': 42}}},
                {},
                ["bq_jdoc #> '{a,b}' > '42'::jsonb"]
            ),
            (
                {'a': {'b': {'$lte': 42}}},
                {},
                ["bq_jdoc #> '{a,b}' <= '42'::jsonb"]
            ),
            (
                {'a': {'b': {'$lt': 42}}},
                {},
                ["bq_jdoc #> '{a,b}' < '42'::jsonb"]
            ),
            (
                {'a': {'b': {'$in': [22, 42]}}},
                {},
                ["bq_jdoc #> '{a,b}' <@ '[22, 42]'::jsonb"]
            ),
        ]

        self._assert_examples(examples)

    def test_bad_op(self):
        query = {
            'a': {'$totallynotavalidop': 42}
        }
        with self.assertRaises(psycopg2.InternalError):
            self.cur.execute("""
            select * from bq_split_queries('{}'::jsonb)
            """.format(json.dumps(query)))
        self.conn.rollback()
