import testutils
import json
import psycopg2


class TestBasics(testutils.BedquiltTestCase):

    def test_extension_presence(self):
        result = self._query("""
        select * from pg_catalog.pg_extension
        where extname = 'bedquilt';
        """)

        self.assertIsNotNone(result)
        self.assertEqual(len(result), 1)

        row = result[0]
        self.assertTrue(len(row) > 0)
        self.assertEqual(row[0], 'bedquilt')

    def test_assert_version(self):
        result = self._query("""
        select bq_util_assert_minimum_version('1.0.0');
        """)
        self.assertEqual(result, [(True,)])


class TestCreateCollection(testutils.BedquiltTestCase):

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


class TestListCollections(testutils.BedquiltTestCase):

    def test_list_collections_empty_instance(self):

        self.cur.execute("select bq_list_collections();")
        result = self.cur.fetchone()

        self.assertIsNone(result)

    def test_list_four_collections(self):
        self.cur.execute("""
        select bq_create_collection('c_one');
        select bq_create_collection('c_two');
        select bq_create_collection('c_three');
        select bq_create_collection('c_four');
        """, )

        self.cur.execute("select bq_list_collections();")
        result = self.cur.fetchall()

        self.assertIsNotNone(result)

        self.assertEqual(map(lambda e: e[0], result),
                         ['c_one', 'c_two', 'c_three', 'c_four'])


class TestDeleteCollection(testutils.BedquiltTestCase):

    def test_delete_non_existant_collection(self):

        self.cur.execute("select bq_delete_collection('one');")
        result = self.cur.fetchone()

        self.assertEqual(len(result), 1)
        self.assertEqual(result[0], False)

    def test_delete_collection(self):

        self.cur.execute("select bq_create_collection('one')")

        self.cur.execute("select bq_delete_collection('one');")
        result = self.cur.fetchone()

        self.assertEqual(len(result), 1)
        self.assertEqual(result[0], True)
