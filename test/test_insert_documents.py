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
            select bq_insert('people', '{}');
        """.format(json.dumps(doc)))

        result = self.cur.fetchone()

        self.assertEqual(
            result, ('user@example.com',)
        )

        self.cur.execute("select bq_list_collections();")
        collections = self.cur.fetchall()
        self.assertIsNotNone(collections)

        self.assertEqual(collections, [("people",)])

    def test_with_non_string_id(self):
        docs = [
            {
                "_id": 42,
                "name": "Penguin",
                "age": "penguin@example.com"
            },
            {
                "_id": ['derp'],
                "name": "Penguin",
                "age": "penguin@example.com"
            },
            {
                "_id": {"name": "Penguin"},
                "age": "penguin@example.com"
            },
            {
                "_id": False,
                "name": "Penguin",
                "age": "penguin@example.com"
            },
            {
                "_id": None,
                "name": "Penguin",
                "age": "penguin@example.com"
            }
        ]
        for doc in docs:
            with self.assertRaises(psycopg2.InternalError):
                self.cur.execute("""
                select bq_insert('people', '{}');
                """.format(json.dumps(doc)))
            self.conn.rollback()

    def test_insert_without_id(self):
        doc = {
            "name": "Some User",
            "age": 20
        }
        self.cur.execute("""
            select bq_insert('people', '{}');
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
            select bq_insert('people', '{}');
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
            select bq_insert('people', '{}');
            """.format(json.dumps(doc)))
        self.conn.rollback()

        self.cur.execute("select count(*) from people;")
        result = self.cur.fetchone()
        self.assertEqual(result, (1,))
