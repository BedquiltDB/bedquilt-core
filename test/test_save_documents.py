import testutils
import json
import string
import psycopg2


class TestSaveDocuments(testutils.BedquiltTestCase):

    def test_save_into_non_existant_collection(self):
        self.cur.execute("""
        select bq_save('things', '{"_id": "aaa", "a": 1}');
        """)
        result = self.cur.fetchall()

        self.cur.execute("""
        select bq_find('things', '{}');
        """)
        result = self.cur.fetchall()

        self.assertEqual(result,
                         [({'_id': 'aaa', 'a': 1},)])

    def test_save_with_no_id(self):
        self.cur.execute("""
        select bq_create_collection('thing');
        """)
        _ = self.cur.fetchall()

        doc = {
            "name": "spanner"
        }

        self.cur.execute("""
        select bq_save('things', '{}');
        """.format(json.dumps(doc)))

        _ = self.cur.fetchall()

        self.cur.execute("""
        select bq_find('things', '{}');
        """)
        result = self.cur.fetchall()

        self.assertEqual(len(result), 1)
        d = result[0][0]
        self.assertEqual(set(d.keys()),
                         set(doc.keys()).union(set(["_id"])))

        self.assertEqual(d['name'], 'spanner')

    def test_save_overwriting_doc(self):
        self.cur.execute("""
        select bq_create_collection('thing');
        """)
        _ = self.cur.fetchall()

        doc = {
            "_id": "aaa",
            "name": "spanner"
        }

        self.cur.execute("""
        select bq_insert('things', '{}');
        """.format(json.dumps(doc)))

        _ = self.cur.fetchall()

        self.cur.execute("""
        select bq_find('things', '{}');
        """)
        result = self.cur.fetchall()

        self.assertEqual(result,
                         [
                             (doc,)
                         ])

        doc['name'] = 'fish'
        doc['color'] = 'blue'

        self.cur.execute("""
        select bq_save('things', '{}');
        """.format(json.dumps(doc)))

        _ = self.cur.fetchall()

        self.cur.execute("""
        select bq_find('things', '{}');
        """)
        result = self.cur.fetchall()

        self.assertEqual(result,
                         [
                             (doc,)
                         ])
