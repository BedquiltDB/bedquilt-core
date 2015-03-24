import testutils
import json
import string
import psycopg2


class TestRemoveDocumnts(testutils.BedquiltTestCase):

    def test_remove_on_empty_collection(self):
        self.cur.execute("""
        select bq_create_collection('people');
        """)
        _ = self.cur.fetchall()

        self.cur.execute("""
        select bq_remove('people', '{"age": 22}')
        """)
        result = self.cur.fetchall()
        self.assertEqual(result,
                         [
                             (0,)
                         ])

    def test_remove_one_on_empty_collection(self):
        self.cur.execute("""
        select bq_create_collection('people');
        """)
        _ = self.cur.fetchall()

        self.cur.execute("""
        select bq_remove_one('people', '{"age": 22}')
        """)
        result = self.cur.fetchall()
        self.assertEqual(result,
                         [
                             (0,)
                         ])

    def test_remove_on_non_existant_collection(self):
        self.cur.execute("""
        select bq_remove('people', '{"age": 22}')
        """)
        result = self.cur.fetchall()
        self.assertEqual(result,
                         [
                             (0,)
                         ])

    def test_remove_one_on_non_existant_collection(self):
        self.cur.execute("""
        select bq_remove_one('people', '{"age": 22}')
        """)
        result = self.cur.fetchall()
        self.assertEqual(result,
                         [
                             (0,)
                         ])

    def test_remove_hitting_single_document(self):

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

        self.cur.execute("""
        select bq_remove('people', '{"age": 34}');
        """)
        result = self.cur.fetchall()

        self.assertEqual(result,
                         [
                             (1,)
                         ])

        self.cur.execute("""
        select bq_find('people', '{}');
        """)
        result = self.cur.fetchall()
        self.assertEqual(result,
                         [
                             (mike,),
                             (jill,),
                             (darren,)
                         ])

    def test_remove_hitting_many_document(self):

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

        self.cur.execute("""
        select bq_remove('people', '{"age": 32}');
        """)
        result = self.cur.fetchall()

        self.assertEqual(result,
                         [
                             (2,)
                         ])

        self.cur.execute("""
        select bq_find('people', '{}');
        """)
        result = self.cur.fetchall()
        self.assertEqual(result,
                         [
                             (sarah,),
                             (darren,)
                         ])


    def test_remove_one_documents(self):

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

        # remove_one a single document matching a wide query
        self.cur.execute("""
        select bq_remove_one('people', '{"age": 32}');
        """)
        result = self.cur.fetchall()

        self.assertEqual(result,
                         [
                             (1,)
                         ])

        self.cur.execute("""
        select bq_find('people', '{}');
        """)
        result = self.cur.fetchall()
        self.assertEqual(result,
                         [
                             (sarah,),
                             (jill,),
                             (darren,)
                         ])

        # remove_one a single document matching a specific query
        self.cur.execute("""
        select bq_remove_one('people', '{"name": "Darren"}');
        """)
        result = self.cur.fetchall()

        self.assertEqual(result,
                         [
                             (1,)
                         ])

        self.cur.execute("""
        select bq_find('people', '{}');
        """)
        result = self.cur.fetchall()
        self.assertEqual(result,
                         [
                             (sarah,),
                             (jill,)
                         ])

        # remove_one a single document matching an _id
        self.cur.execute("""
        select bq_remove_one('people', '{"_id": "jill@example.com"}');
        """)
        result = self.cur.fetchall()

        self.assertEqual(result,
                         [
                             (1,)
                         ])

        self.cur.execute("""
        select bq_find('people', '{}');
        """)
        result = self.cur.fetchall()
        self.assertEqual(result,
                         [
                             (sarah,)
                         ])

    def test_remove_one_by_id_on_non_existant_collection(self):
        self.cur.execute("""
        select bq_remove_one_by_id('people', 'jill@example.com');
        """)
        result = self.cur.fetchall()
        self.assertEqual(result, [ (0,) ])

    def test_remove_one_by_id_on_empty_collection(self):
        self.cur.execute("""
        select bq_create_collection('people');
        """)
        _ = self.cur.fetchall()

        self.cur.execute("""
        select bq_remove_one_by_id('people', 'jill@example.com');
        """)
        result = self.cur.fetchall()
        self.assertEqual(result, [ (0,) ])

    def test_remove_one_by_id(self):

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

        # remove an existing document
        self.cur.execute("""
        select bq_remove_one_by_id('people', 'jill@example.com')
        """)
        result = self.cur.fetchall()

        self.assertEqual(result,
                         [
                             (1,)
                         ])

        self.cur.execute("""
        select bq_find('people', '{}');
        """)
        result = self.cur.fetchall()
        self.assertEqual(result,
                         [
                             (sarah,),
                             (mike,),
                             (darren,)
                         ])


        # remove a document which is not in collection
        self.cur.execute("""
        select bq_remove_one_by_id('people', 'xxxxx')
        """)
        result = self.cur.fetchall()

        self.assertEqual(result,
                         [
                             (0,)
                         ])

        self.cur.execute("""
        select bq_find('people', '{}');
        """)
        result = self.cur.fetchall()
        self.assertEqual(result,
                         [
                             (sarah,),
                             (mike,),
                             (darren,)
                         ])
