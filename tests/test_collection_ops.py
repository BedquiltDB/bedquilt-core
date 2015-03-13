import unittest
import testutils


class TestCreateCollection(unittest.TestCase):

    def setUp(self):
        self.conn = testutils.get_pg_connection()

    def test_something(self):
        self.assertTrue(True)
