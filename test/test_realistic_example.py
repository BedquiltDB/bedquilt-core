import testutils
import json
import string
import psycopg2


def post_id(doc):
    return doc['data']['id']


def map_post_ids(result_set):
    return map(lambda r: r[0]['data']['id'], result_set)


class TestFindOneWithSkipAndSort(testutils.BedquiltTestCase):

    def populate(self):
        with open('test/fixtures/python_reddit.json') as f:
            data_string = f.read()
            data = json.loads(data_string)
            posts = data['data']['children']
            for post in posts:
                self._insert('posts', post)

    def test_count(self):
        self.populate()
        result = self._query(
            "select bq_count('posts', '{}')"
        )
        self.assertEqual(result[0][0], 101)

        result = self._query(
            """select bq_count('posts', '{"data": {"author": "kungfooey"}}')"""
        )
        self.assertEqual(result[0][0], 2)

        result = self._query(
            """select bq_count('posts', '{"data": {"stickied": false}}')"""
        )
        self.assertEqual(result[0][0], 100)

    def test_find_one(self):
        self.populate()

        result = self._query("""
        select bq_find_one('posts', '{"data": {"score": 3}}')
        """)
        self.assertEqual(post_id(result[0][0]), "4xug6r")

        result = self._query("""
        select bq_find_one('posts', '{"data": {"author": "ExoHuman15"}}')
        """)
        self.assertEqual(post_id(result[0][0]), "4xt19h")

        result = self._query("""
        select bq_find_one('posts', '{"data": {"score": {"$gt": 5, "$lte": 22}}}')
        """)
        self.assertEqual(post_id(result[0][0]), "4xx22u")

        result = self._query("""
        select bq_find_one(
          'posts',
          '{"data": {"score": {"$gt": 5, "$lte": 22}}}',
          2,
          '[{"data.score": -1}]'
        )
        """)
        self.assertEqual(post_id(result[0][0]), "4xc5ok")

        result = self._query("""
        select bq_find_one(
          'posts',
          '{"data": {"score": {"$gte": 20},
                     "permalink": {"$regex": ".*basics.*"}}}'
        )
        """)
        self.assertEqual(post_id(result[0][0]), "4xumhx")

    def test_find(self):
        self.populate()

        result = self._query("""
        select bq_find(
          'posts',
          '{"data": {"score": {"$gte": 2, "$lte": 5}}}',
          0,
          4
        )
        """)
        self.assertEqual(map_post_ids(result), ['4xwvu9', '4xvf77', '4xw9x8', '4xv0dk'])

        result = self._query("""
        select bq_find(
          'posts',
          '{"data": {"score": {"$gte": 2, "$lte": 5}}}',
          0,
          4,
          '[{"data.score": -1}]'
        )
        """)
        self.assertEqual(map_post_ids(result), ['4xvf77', '4xw9x8', '4xc6d5', '4x7nvy'])

        result = self._query("""
        select bq_find(
          'posts',
          '{"data": {"is_self": {"$noteq": false}}}',
          0,
          4,
          '[{"data.score": 1}]'
        )
        """)
        self.assertEqual(map_post_ids(result), ['4xxe30', '4xu3h9', '4xu9r9', '4xtiu9'])

        result = self._query("""
        select bq_find(
          'posts',
          '{"data": {"is_self": {"$noteq": false}}}',
          0,
          4,
          '[{"data.score": -1}]'
        )
        """)
        self.assertEqual(map_post_ids(result), ['3kestk', '4x8192', '4xc5ok', '4xdwbg'])
