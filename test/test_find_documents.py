import testutils
import json
import string
import psycopg2


class TestCollectionCount(testutils.BedquiltTestCase):

    def test_count_on_empty_collection(self):
        _ = self._query("select bq_create_collection('people');")
        result = self._query("""
        select bq_count('people');
        """)
        self.assertEqual(result, [(0,)])

    def test_count_on_non_exsistant_collection(self):
        result = self._query("""
        select bq_count('people')
        """)
        self.assertEqual(result, [(0,)])

    def test_count_with_one_doc(self):
        _ = self._query("""
        select bq_insert('things', '{"a": 1}')
        """)

        result = self._query("""
        select bq_count('things')
        """)
        self.assertEqual(result, [(1,)])

class TestFindDocuments(testutils.BedquiltTestCase):

    def test_find_on_empty_collection(self):

        queries = [
            {},
            {"likes": ["icecream"]},
            {"name": "Mike"},
            {"_id": "mike"}
        ]

        for q in queries:
            # find_one
            self.cur.execute("""
            select bq_find_one('people', '{query}')
            """.format(query=json.dumps(q)))
            result = self.cur.fetchall()
            self.assertEqual(result, [])

            # find
            self.cur.execute("""
            select bq_find('people', '{query}')
            """.format(query=json.dumps(q)))
            result = self.cur.fetchall()
            self.assertEqual(result, [])

    def test_find_one_existing_document(self):

        sarah = {'_id': "sarah@example.com",
                 'name': "Sarah",
                 'age': 34,
                 'likes': ['icecream', 'cats']}
        mike = {'_id': "mike@example.com",
                'name': "Mike",
                'age': 32,
                'likes': ['cats', 'crochet']}

        self._insert('people', sarah)
        self._insert('people', mike)

        # find sarah
        self.cur.execute("""
        select bq_find_one('people', '{"name": "Sarah"}')
        """)

        result = self.cur.fetchall()
        self.assertEqual(result,
                         [
                             (sarah,)
                         ])

        # find mike
        self.cur.execute("""
        select bq_find_one('people', '{"name": "Mike"}')
        """)

        result = self.cur.fetchall()
        self.assertEqual(result,
                         [
                             (mike,)
                         ])
        # find no-one
        self.cur.execute("""
        select bq_find_one('people', '{"name": "XXXXXXX"}')
        """)

        result = self.cur.fetchall()
        self.assertIsNotNone(result)
        self.assertEqual(len(result), 0)

    def test_find_one_by_id(self):
        sarah = {'_id': "sarah@example.com",
                 'name': "Sarah",
                 'age': 34,
                 'likes': ['icecream', 'cats']}
        mike = {'_id': "mike@example.com",
                'name': "Mike",
                'age': 32,
                'likes': ['cats', 'crochet']}

        self._insert('people', sarah)
        self._insert('people', mike)

        # find sarah
        self.cur.execute("""
        select bq_find_one_by_id('people', 'sarah@example.com')
        """)

        result = self.cur.fetchall()
        self.assertEqual(result,
                         [
                             (sarah,)
                         ])

        # find mike
        self.cur.execute("""
        select bq_find_one_by_id('people', 'mike@example.com')
        """)

        result = self.cur.fetchall()
        self.assertEqual(result,
                         [
                             (mike,)
                         ])
        # find no-one
        self.cur.execute("""
        select bq_find_one_by_id('people', 'xxxx')
        """)

        result = self.cur.fetchall()
        self.assertIsNotNone(result)
        self.assertEqual(len(result), 0)


    def test_find_existing_documents(self):

        sarah = {'_id': "sarah@example.com",
                 'name': "Sarah",
                 'city': "Glasgow",
                 'age': 34,
                 'likes': ['icecream', 'cats']}
        mike = {'_id': "mike@example.com",
                'name': "Mike",
                'city': "Edinburgh",
                'age': 32,
                'likes': ['cats', 'crochet']}
        jill = {'_id': "jill@example.com",
                'name': "Jill",
                'city': "Glasgow",
                'age': 32,
                'likes': ['code', 'crochet']}
        darren = {'_id': "darren@example.com",
                'name': "Darren",
                'city': "Manchester"}


        self._insert('people', sarah)
        self._insert('people', mike)
        self._insert('people', jill)
        self._insert('people', darren)

        # find matching an _id
        self.cur.execute("""
        select bq_find('people', '{"_id": "jill@example.com"}')
        """)
        result = self.cur.fetchall()
        self.assertEqual(result,
                         [
                             (jill,)
                         ])

        # find by match on the city field
        self.cur.execute("""
        select bq_find('people', '{"city": "Glasgow"}')
        """)
        result = self.cur.fetchall()
        self.assertEqual(result,
                         [
                             (sarah,),
                             (jill,)
                         ])
        self.cur.execute("""
        select bq_find('people', '{"city": "Edinburgh"}')
        """)
        result = self.cur.fetchall()
        self.assertEqual(result,
                         [
                             (mike,),
                         ])
        self.cur.execute("""
        select bq_find('people', '{"city": "Manchester"}')
        """)
        result = self.cur.fetchall()
        self.assertEqual(result,
                         [
                             (darren,),
                         ])
        self.cur.execute("""
        select bq_find('people', '{"city": "New York"}')
        """)
        result = self.cur.fetchall()
        self.assertEqual(result,
                         [])

        # find all
        self.cur.execute("""
        select bq_find('people', '{}')
        """)
        result = self.cur.fetchall()
        self.assertEqual(result,
                         [
                             (sarah,),
                             (mike,),
                             (jill,),
                             (darren,)
                         ])
