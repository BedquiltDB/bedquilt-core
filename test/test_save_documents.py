import testutils
import json
import string
import psycopg2


class TestSaveDocuments(testutils.BedquiltTestCase):

    def test_save_into_non_existant_collection(self):
        _ = self._query("""
        select bq_save('things', '{"_id": "aaa", "a": 1}');
        """)

        result = self._query("""
        select bq_find('things', '{}');
        """)

        self.assertEqual(result,
                         [({'_id': 'aaa', 'a': 1},)])

    def test_save_with_no_id(self):
        _ = self._query("""
        select bq_create_collection('things');
        """)

        doc = {
            "name": "spanner"
        }

        _ = self._query("""
        select bq_save('things', '{}');
        """.format(json.dumps(doc)))

        result = self._query("""
        select bq_find('things', '{}');
        """)

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

        dud = {'_id': 'dud', 'name': 'dud'}
        doc = {
            "_id": "aaa",
            "name": "spanner"
        }

        self._insert('things', dud)
        _ = self.cur.fetchall()
        self._insert('things', doc)
        _ = self.cur.fetchall()

        result = self._query("""
        select bq_find('things', '{}');
        """)

        self.assertEqual(result,
                         [
                             (dud,),
                             (doc,)
                         ])

        # Mutate and save
        doc['name'] = 'fish'
        doc['color'] = 'blue'

        self._query("""
        select bq_save('things', '{}');
        """.format(json.dumps(doc)))

        result = self._query("""
        select bq_find('things', '{}');
        """)

        self.assertEqual(result,
                         [
                             (dud,),
                             (doc,)
                         ])

        # Mutate and save again
        doc['name'] = 'trout'
        doc['color'] = 'pink'
        doc['count'] = 22

        self._query("""
        select bq_save('things', '{}');
        """.format(json.dumps(doc)))

        result = self._query("""
        select bq_find('things', '{}');
        """)

        self.assertEqual(result,
                         [
                             (dud,),
                             (doc,)
                         ])
