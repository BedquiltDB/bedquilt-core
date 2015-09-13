import testutils
import json
import string
import psycopg2


class TestFindWithSkipAndLimit(testutils.BedquiltTestCase):

    def test_on_empty_collection(self):
        self.cur.execute("""
        select bq_find('things', '{}', 4, 2)
        """)
        result = self.cur.fetchall()
        self.assertEqual(result, [])

        self.cur.execute("""
        select bq_create_collection('things');
        """)
        _ = self.cur.fetchall()

        self.cur.execute("""
        select bq_find('things', '{}', 4, 2)
        """)
        result = self.cur.fetchall()
        self.assertEqual(result, [])

    def test_on_small_collection(self):
        for i in range(10):
            self.cur.execute("""
            select bq_insert('things', '{}')
            """.format(json.dumps({'num': i})))
            _ = self.cur.fetchall()

        # within range of collection
        self.cur.execute("""
        select bq_find('things', '{}', 4, 2)
        """)
        result = self.cur.fetchall()
        self.assertEqual(len(result), 2)
        self.assertEqual(map(lambda x: x[0]['num'], result),
                         [4, 5])

        # on edge of collection
        self.cur.execute("""
        select bq_find('things', '{}', 9, 4)
        """)
        result = self.cur.fetchall()
        self.assertEqual(len(result), 1)
        self.assertEqual(map(lambda x: x[0]['num'], result),
                         [9])

        # beyond end of collection
        self.cur.execute("""
        select bq_find('things', '{}', 30, 4)
        """)
        result = self.cur.fetchall()
        self.assertEqual(result, [])

    def test_skip_alone(self):
        for i in range(10):
            self.cur.execute("""
            select bq_insert('things', '{}')
            """.format(json.dumps({'num': i})))
            _ = self.cur.fetchall()

        # within range of collection
        self.cur.execute("""
        select bq_find('things', '{}', 6)
        """)
        result = self.cur.fetchall()
        self.assertEqual(len(result), 4)
        self.assertEqual(map(lambda x: x[0]['num'], result),
                         [6, 7, 8, 9])


class TestFindWithSkipLimitAndSort(testutils.BedquiltTestCase):

    def populate(self):
        docs = [
            {
                "name": "Sarah",
                "pet": {
                    "name": "Snowball",
                    "age": 12
                }
            },
            {
                "name": "Jane",
                "pet": {
                    "name": "Mittens",
                    "age": 4
                }
            },
            {
                "name": "Eliot",
                "pet": {
                    "name": "Wilbur",
                    "age": 2
                }
            },
            {
                "name": "Mike",
                "pet": {
                    "name": "Rufus",
                    "age": 22
                }
            },
            {
                "name": "Carly",
                "pet": {
                    "name": "Squinty",
                    "age": 3
                }
            }
        ]
        self._query("select bq_delete_collection('people')");
        for person in docs:
            self._query("""
            select bq_save('people', '{}')
            """.format(json.dumps(person)))

    def test_sort_on_empty_collection(self):
        result = self._query("""
        select bq_find('things', '{}', 4, 2, '{"pet.age": 1}')
        """)
        self.assertEqual(result, [])

        self._query("""
        select bq_create_collection('things');
        """)

        result = self._query("""
        select bq_find('things', '{}', 4, 2, '{"pet.age": 1}')
        """)
        self.assertEqual(result, [])

    def test_simple_sort(self):
        self.populate()

        # ascending
        result = self._query("""
        select bq_find('people', '{}', 0, null, '{"pet.age": 1}')
        """)
        ages = map(lambda x: x[0]['pet']['age'], result)
        # ages should be in ascending order
        self.assertEqual(ages, sorted(ages))

        # descending
        result = self._query("""
        select bq_find('people', '{}', 0, null, '{"pet.age": -1}')
        """)
        ages = map(lambda x: x[0]['pet']['age'], result)
        # ages should be in ascending order
        self.assertEqual(ages, sorted(ages, reverse=True))
