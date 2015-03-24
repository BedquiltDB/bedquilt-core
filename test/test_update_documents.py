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
