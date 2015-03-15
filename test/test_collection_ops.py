import unittest
import testutils


class TestCreateCollection(unittest.TestCase):

    def setUp(self):
        self.conn = testutils.get_pg_connection()
        self.cur = self.conn.cursor()
        testutils.clean_database(self.conn)

    def test_creating_a_new_collection(self):
        # create a collection 'testone'
        self.cur.execute("select bq_create_collection('testone')")
        result = self.cur.fetchone()

        self.assertEqual(len(result), 1)
        self.assertEqual(result[0], True)

        # create it again
        self.cur.execute("select bq_create_collection('testone')")
        result = self.cur.fetchone()

        self.assertEqual(len(result), 1)
        self.assertEqual(result[0], False)


class TestListCollections(unittest.TestCase):

    def setUp(self):
        self.conn = testutils.get_pg_connection()
        self.cur = self.conn.cursor()

        testutils.clean_database(self.conn)

    def test_list_collections_empty_instance(self):

        self.cur.execute("select bq_list_collections();")
        result = self.cur.fetchone()

        self.assertIsNone(result)
