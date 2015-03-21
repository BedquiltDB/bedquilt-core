import testutils
import json
import string
import psycopg2


class TestInsertDocument(testutils.BedquiltTestCase):

    def test_insert_into_non_existant_collection(self):
        doc = {
            "_id": "user@example.com",
            "name": "Some User",
            "age": 20
        }

        self.cur.execute("""
            select bq_insert_document('people', '{}');
        """.format(json.dumps(doc)))

        result = self.cur.fetchone()

        self.assertEqual(
            result, ('user@example.com',)
        )

        self.cur.execute("select bq_list_collections();")
        collections = self.cur.fetchall()
        self.assertIsNotNone(collections)

        self.assertEqual(collections, [("people",)])

    def test_insert_without_id(self):
        doc = {
            "name": "Some User",
            "age": 20
        }
        self.cur.execute("""
            select bq_insert_document('people', '{}');
        """.format(json.dumps(doc)))

        result = self.cur.fetchone()

        self.assertIsNotNone(result)
        self.assertEqual(type(result), tuple)
        self.assertEqual(len(result), 1)

        _id = result[0]
        self.assertIn(type(_id), {str, unicode})
        self.assertEqual(len(_id), 24)
        for character in _id:
            self.assertIn(character, string.hexdigits)

    def test_insert_with_repeat_id(self):
        doc = {
            "_id": "user_one",
            "name": "Some User",
            "age": 20
        }
        self.cur.execute("""
            select bq_insert_document('people', '{}');
        """.format(json.dumps(doc)))

        result = self.cur.fetchone()

        self.assertIsNotNone(result)
        self.assertEqual(type(result), tuple)
        self.assertEqual(len(result), 1)
        _id = result[0]
        self.assertEqual(_id, "user_one")

        self.conn.commit()

        with self.assertRaises(psycopg2.IntegrityError):
            self.cur.execute("""
            select bq_insert_document('people', '{}');
            """.format(json.dumps(doc)))
        self.conn.rollback()

        self.cur.execute("select count(*) from people;")
        result = self.cur.fetchone()
        self.assertEqual(result, (1,))


class TestFindDocuments(testutils.BedquiltTestCase):

    def _insert(self, collection, document):
        self.cur.execute("""
        select bq_insert_document(
            '{coll}',
            '{doc}'
        );
        """.format(coll=collection, doc=json.dumps(document)))

    def test_find_on_empty_collection(self):

        queries = [
            {},
            {"likes": ["icecream"]},
            {"name": "Mike"},
            {"_id": "mike"}
        ]

        for q in queries:
            # findone
            self.cur.execute("""
            select bq_findone_document('people', '{query}')
            """.format(query=json.dumps(q)))
            result = self.cur.fetchall()
            self.assertEqual(result, [])

            # find
            self.cur.execute("""
            select bq_find_documents('people', '{query}')
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
        select bq_findone_document('people', '{"name": "Sarah"}')
        """)

        result = self.cur.fetchall()
        self.assertEqual(result,
                         [
                             (sarah,)
                         ])

        # find mike
        self.cur.execute("""
        select bq_findone_document('people', '{"name": "Mike"}')
        """)

        result = self.cur.fetchall()
        self.assertEqual(result,
                         [
                             (mike,)
                         ])
        # find no-one
        self.cur.execute("""
        select bq_findone_document('people', '{"name": "XXXXXXX"}')
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
        select bq_find_documents('people', '{"_id": "jill@example.com"}')
        """)
        result = self.cur.fetchall()
        self.assertEqual(result,
                         [
                             (jill,)
                         ])

        # find by match on the city field
        self.cur.execute("""
        select bq_find_documents('people', '{"city": "Glasgow"}')
        """)
        result = self.cur.fetchall()
        self.assertEqual(result,
                         [
                             (sarah,),
                             (jill,)
                         ])
        self.cur.execute("""
        select bq_find_documents('people', '{"city": "Edinburgh"}')
        """)
        result = self.cur.fetchall()
        self.assertEqual(result,
                         [
                             (mike,),
                         ])
        self.cur.execute("""
        select bq_find_documents('people', '{"city": "Manchester"}')
        """)
        result = self.cur.fetchall()
        self.assertEqual(result,
                         [
                             (darren,),
                         ])
        self.cur.execute("""
        select bq_find_documents('people', '{"city": "New York"}')
        """)
        result = self.cur.fetchall()
        self.assertEqual(result,
                         [])

        # find all
        self.cur.execute("""
        select bq_find_documents('people', '{}')
        """)
        result = self.cur.fetchall()
        self.assertEqual(result,
                         [
                             (sarah,),
                             (mike,),
                             (jill,),
                             (darren,)
                         ])
