import testutils
import json
import psycopg2


class TestAdvancedQueries(testutils.BedquiltTestCase):

    def test_eq_find_one(self):
        mike = {'_id': "mike@example.com",
                'name': "Mike",
                'city': "Edinburgh",
                'age': 32,
                'likes': ['cats', 'crochet', 'code']}
        jill = {'_id': "jill@example.com",
                'name': "Jill",
                'city': "Glasgow",
                'age': 32,
                'likes': ['code', 'crochet']}
        darren = {'_id': "darren@example.com",
                'name': "Darren",
                'city': "Manchester"}
        sarah = {'_id': "sarah@example.com",
                 'name': "Sarah",
                 'city': "Glasgow",
                 'age': 34,
                 'likes': ['icecream', 'cats']}

        self._insert('people', mike)
        self._insert('people', jill)
        self._insert('people', darren)
        self._insert('people', sarah)

        result = self._query("""
        select bq_find_one('people', '{"likes": {"$eq": ["code", "crochet"]}}')
        """)
        self.assertEqual(result, [(jill,)])

    def test_gt_find_one(self):
        mike = {'_id': "mike@example.com",
                'name': "Mike",
                'city': "Edinburgh",
                'age': 32,
                'likes': ['cats', 'crochet', 'code']}
        jill = {'_id': "jill@example.com",
                'name': "Jill",
                'city': "Glasgow",
                'age': 32,
                'likes': ['code', 'crochet']}
        darren = {'_id': "darren@example.com",
                'name': "Darren",
                'city': "Manchester"}
        sarah = {'_id': "sarah@example.com",
                 'name': "Sarah",
                 'city': "Glasgow",
                 'age': 34,
                 'likes': ['icecream', 'cats']}

        self._insert('people', mike)
        self._insert('people', jill)
        self._insert('people', darren)
        self._insert('people', sarah)

        result = self._query("""
        select bq_find_one('people', '{"age": {"$gt": 32}}')
        """)
        self.assertEqual(result, [(sarah,)])

        result = self._query("""
        select bq_find_one('people', '{"age": {"$gt": 30}}')
        """)
        self.assertEqual(result, [(mike,)])

        result = self._query("""
        select bq_find_one('people', '{"age": {"$gt": 34}}')
        """)
        self.assertEqual(result, [])

        result = self._query("""
        select bq_find_one('people', '{"age": {"$gte": 34}}')
        """)
        self.assertEqual(result, [(sarah,)])
