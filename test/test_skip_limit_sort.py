import testutils
import json
import string
import psycopg2
import time


def _names(rows):
    return map(lambda x: x[0]['name'], rows)

def _labels(rows):
    return map(lambda x: x[0]['label'], rows)


class TestFindOneWithSkipAndSort(testutils.BedquiltTestCase):

    def populate(self):
        docs = [
            {
                "name": "Sarah",
                "pet": {
                    "name": "Snowball",
                    "species": "dog",
                    "age": 12
                }
            },
            {
                "name": "Jane",
                "pet": {
                    "name": "Mittens",
                    "species": "cat",
                    "age": 4
                }
            },
            {
                "name": "Eliot",
                "pet": {
                    "name": "Wilbur",
                    "species": "dog",
                    "age": 2
                }
            },
            {
                "name": "Mike",
                "pet": {
                    "name": "Rufus",
                    "species": "dog",
                    "age": 22
                }
            },
            {
                "name": "Carly",
                "pet": {
                    "name": "Squinty",
                    "species": "cat",
                    "age": 3
                }
            }
        ]
        self._query("select bq_delete_collection('people')");
        for person in docs:
            self._query("""
            select bq_save('people', '{}')
            """.format(json.dumps(person)))


    def test_on_empty_collection(self):
        self.cur.execute("""
        select bq_find_one('things', '{}', 4, '[{"pet.age": 1}]')
        """)
        result = self.cur.fetchall()
        self.assertEqual(result, [])

        self.cur.execute("""
        select bq_create_collection('things');
        """)
        _ = self.cur.fetchall()

        self.cur.execute("""
        select bq_find_one('things', '{}', 4, '[{"pet.age": 1}]')
        """)
        result = self.cur.fetchall()
        self.assertEqual(result, [])

    def test_simple_sort(self):
        self.populate()

        # ascending
        result = self._query("""
        select bq_find_one('people', '{}', 0, '[{"pet.age": 1}]')
        """)
        self.assertEqual(_names(result), ['Eliot'])

        # descending
        result = self._query("""
        select bq_find_one('people', '{}', 0, '[{"pet.age": -1}]')
        """)
        ages = map(lambda x: x[0]['pet']['age'], result)
        # ages should be in ascending order
        self.assertEqual(_names(result), ['Mike'])

        # with an actual query
        result = self._query("""
        select bq_find_one('people', '{"pet": {"species": "cat"}}',
                       0, '[{"pet.age": 1}]')
        """)
        self.assertEqual(_names(result), ['Carly'])


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
                    "species": "dog",
                    "age": 12
                }
            },
            {
                "name": "Jane",
                "pet": {
                    "name": "Mittens",
                    "species": "cat",
                    "age": 4
                }
            },
            {
                "name": "Eliot",
                "pet": {
                    "name": "Wilbur",
                    "species": "cat",
                    "age": 2
                }
            },
            {
                "name": "Mike",
                "pet": {
                    "name": "Rufus",
                    "species": "dog",
                    "age": 22
                }
            },
            {
                "name": "Carly",
                "pet": {
                    "name": "Squinty",
                    "species": "cat",
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
        select bq_find('things', '{}', 4, 2, '[{"pet.age": 1}]')
        """)
        self.assertEqual(result, [])

        self._query("""
        select bq_create_collection('things');
        """)

        result = self._query("""
        select bq_find('things', '{}', 4, 2, '[{"pet.age": 1}]')
        """)
        self.assertEqual(result, [])

    def test_simple_sort(self):
        self.populate()

        # ascending
        result = self._query("""
        select bq_find('people', '{}', 0, null, '[{"pet.age": 1}]')
        """)
        ages = map(lambda x: x[0]['pet']['age'], result)
        # ages should be in ascending order
        self.assertEqual(ages, sorted(ages))

        # descending
        result = self._query("""
        select bq_find('people', '{}', 0, null, '[{"pet.age": -1}]')
        """)
        ages = map(lambda x: x[0]['pet']['age'], result)
        # ages should be in ascending order
        self.assertEqual(ages, sorted(ages, reverse=True))

        # with an actual query
        result = self._query("""
        select bq_find('people', '{"pet": {"species": "cat"}}',
                       0, null, '[{"pet.age": 1}]')
        """)
        self.assertEqual(_names(result),
                         ['Eliot', 'Carly', 'Jane'])

    def test_sort_with_skip_and_limit(self):
        self.populate()

        # with an actual query, skip one, limit one
        result = self._query("""
        select bq_find('people', '{"pet": {"species": "cat"}}',
                       1, 1, '[{"pet.age": 1}]')
        """)
        self.assertEqual(_names(result),
                         ['Carly'])

        # no skip, limit two, ascending
        result = self._query("""
        select bq_find('people', '{}', 0, 2, '[{"pet.age": 1}]')
        """)
        self.assertEqual(_names(result),
                         ['Eliot', 'Carly'])

        # skip one, limit two, ascending
        result = self._query("""
        select bq_find('people', '{}', 1, 2, '[{"pet.age": 1}]')
        """)
        self.assertEqual(_names(result),
                         ['Carly', 'Jane'])

        # skip one, limit two, descending
        result = self._query("""
        select bq_find('people', '{}', 1, 2, '[{"pet.age": -1}]')
        """)
        self.assertEqual(_names(result),
                         ['Sarah', 'Jane'])


class TestSortOnTwoFields(testutils.BedquiltTestCase):

    def test_sort_on_two_fields(self):
        docs = [
            {"name": "aa", "b": {"c": 4}},
            {"name": "hh", "b": {"c": 1}},
            {"name": "bb", "b": {"c": 1}},
            {"name": "yy", "b": {"c": 4}},
            {"name": "jj", "b": {"c": 4}},
            {"name": "kk", "b": {"c": 1}},
            {"name": "ff", "b": {"c": 1}}
        ]
        for doc in docs:
            _ = self._query("""
            select bq_insert('things', '{}')
            """.format(json.dumps(doc)))

        # ascending b.c, ascending name
        result = self._query("""
        select bq_find('things', '{}', 0, null, '[{"b.c": 1}, {"name": 1}]')
        """)
        self.assertEqual(_names(result),
                         ["bb", "ff", "hh", "kk",
                          "aa", "jj", "yy"])

        # ascending b.c, descending name
        result = self._query("""
        select bq_find('things', '{}', 0, null, '[{"b.c": 1}, {"name": -1}]')
        """)
        self.assertEqual(_names(result),
                         ["kk", "hh", "ff", "bb",
                          "yy", "jj", "aa"])

        # # descending b.c, ascending name
        result = self._query("""
        select bq_find('things', '{}', 0, null, '[{"b.c": -1}, {"name": 1}]')
        """)
        self.assertEqual(_names(result),
                         ["aa", "jj", "yy",
                          "bb", "ff", "hh", "kk"])

        # # descending b.c, descending name
        result = self._query("""
        select bq_find('things', '{}', 0, null, '[{"b.c": -1}, {"name": -1}]')
        """)
        self.assertEqual(_names(result),
                         ["yy", "jj", "aa",
                          "kk", "hh", "ff", "bb"])


class TestSortOnCreatedAndUpdated(testutils.BedquiltTestCase):

    def populate(self):
        docs = [
            {'_id': 'aa', 'label': 'a', 'n': 2},
            {'_id': 'bb', 'label': 'b', 'n': 1},
            {'_id': 'cc', 'label': 'c', 'n': 4},
            {'_id': 'dd', 'label': 'd', 'n': 1},
            {'_id': 'ee', 'label': 'e', 'n': 10}
        ]
        for doc in docs:
            _ = self._query("""
            select bq_insert('things', '{}')
            """.format(json.dumps(doc)))
        b = docs[1]
        d = docs[3]
        b['wat'] = True
        d['wat'] = False
        for doc in [b, d]:
            time.sleep(0.1)
            _ = self._query("""
            select bq_save('things', %s)
            """, (json.dumps(doc),))

    def test_created_and_updated(self):
        self.populate()

        # $created
        result = self._query("""
        select bq_find('things', '{}', 0, null, '[{"$created": 1}]')
        """)
        self.assertEqual(_labels(result),
                         ['a', 'b', 'c', 'd', 'e'])

        result = self._query("""
        select bq_find('things', '{}', 0, null, '[{"$created": -1}]')
        """)
        self.assertEqual(_labels(result),
                         ['e', 'd', 'c', 'b', 'a'])

        # n descending, then $created ascending
        result = self._query("""
        select bq_find('things', '{}', 0, null, '[{"n": -1}, {"$created": 1}]')
        """)
        self.assertEqual(_labels(result),
                         ['e', 'c', 'a', 'b', 'd'])

        # n descending, then $created descending
        result = self._query("""
        select bq_find('things', '{}', 0, null, '[{"n": -1}, {"$created": -1}]')
        """)
        self.assertEqual(_labels(result),
                         ['e', 'c', 'a', 'd', 'b'])

        # $updated
        result = self._query("""
        select bq_find('things', '{}', 0, null, '[{"$updated": 1}]')
        """)
        self.assertEqual(_labels(result),
                         ['a', 'c', 'e', 'b', 'd'])

        result = self._query("""
        select bq_find('things', '{}', 0, null, '[{"n": -1}, {"$updated": -1}]')
        """)
        self.assertEqual(_labels(result),
                         ['e', 'c', 'a', 'd', 'b']
        )

        result = self._query("""
        select bq_find('things', '{}', 0, null, '[{"$updated": -1}]')
        """)
        self.assertEqual(_labels(result),
                         ['d', 'b', 'e', 'c', 'a'])

        # n descending, then $updated ascending
        result = self._query("""
        select bq_find('things', '{}', 0, null, '[{"n": -1}, {"$updated": 1}]')
        """)
        self.assertEqual(_labels(result),
                         ['e', 'c', 'a', 'b', 'd']
        )
