import unittest
import testutils


class TestCreateCollection(unittest.TestCase):

    def setUp(self):
        self.conn = testutils.get_pg_connection()

    def test_creating_a_new_collection(self):
        cur = self.conn.cursor()

        # create a collection 'testone'
        cur.execute("select bq_create_collection('testone')")
        result = cur.fetchone()

        self.assertEqual(len(result), 1)
        self.assertEqual(result[0], True)

        # create it again
        cur.execute("select bq_create_collection('testone')")
        result = cur.fetchone()

        self.assertEqual(len(result), 1)
        self.assertEqual(result[0], False)
