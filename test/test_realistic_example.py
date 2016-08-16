import testutils
import json
import string
import psycopg2


class TestFindOneWithSkipAndSort(testutils.BedquiltTestCase):

    def populate(self):
        with open('test/fixtures/python_reddit.json') as f:
            data_string = f.read()
            data = json.loads(data_string)
            posts = data['data']['children']
            for post in posts:
                self._insert('posts', post)

    def test_count(self):
        self.populate()
        result = self._query("select bq_count('posts', '{}')")
        self.assertEqual(result[0][0], 101)
