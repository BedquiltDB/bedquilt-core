import testutils
import json
import psycopg2


class TestAdvancedQueries(testutils.BedquiltTestCase):

    def test_eq(self):
        rows = [
            {"_id": "aa", "label": "a", "n": 1,  "color": "red"},
            {"_id": "bb", "label": "b", "n": 4,  "color": "red"},
            {"_id": "cc", "label": "c", "n": 8,  "color": "red"},
            {"_id": "dd", "label": "d", "n": 16, "color": "blue"},
            {"_id": "ee", "label": "e", "n": 8,  "color": "blue"},
            {"_id": "ff", "label": "f", "n": 16, "color": "red"},
            {"_id": "dud", "color": "blue"}
        ]
        for row in rows:
            self._insert('things', row)

        # find_one
        result = self._query(
            "select bq_find_one('things', '{}')".format(json.dumps({
                'color': 'blue',
                'n': {'$eq': 8},
            }))
        )
        self.assertEqual(result[0][0]['label'], 'e')

        result = self._query(
            "select bq_find_one('things', '{}')".format(json.dumps({
                'color': 'red',
                'n': {'$eq': 16},
            }))
        )
        self.assertEqual(result[0][0]['label'], 'f')

    def test_noteq(self):
        rows = [
            {"_id": "aa", "label": "a", "n": 1,  "color": "red"},
            {"_id": "bb", "label": "b", "n": 4,  "color": "red"},
            {"_id": "dud", "color": "blue"}
        ]
        for row in rows:
            self._insert('things', row)

        # find_one
        result = self._query(
            "select bq_find_one('things', '{}')".format(json.dumps({
                'color': 'red',
                'n': {'$noteq': 1},
            }))
        )
        self.assertEqual(result[0][0]['label'], 'b')

        result = self._query(
            "select bq_find_one('things', '{}')".format(json.dumps({
                'color': 'red',
                'n': {'$noteq': 4},
            }))
        )
        self.assertEqual(result[0][0]['label'], 'a')

    def test_gt_and_gte(self):
        rows = [
            {"_id": "aa", "label": "a", "n": 1,  "color": "red"},
            {"_id": "bb", "label": "b", "n": 4,  "color": "red"},
            {"_id": "cc", "label": "c", "n": 8,  "color": "red"},
            {"_id": "dd", "label": "d", "n": 16, "color": "blue"},
            {"_id": "ee", "label": "e", "n": 8,  "color": "blue"},
            {"_id": "ff", "label": "f", "n": 16, "color": "red"},
            {"_id": "dud", "color": "blue"}
        ]
        for row in rows:
            self._insert('things', row)

        # find_one
        result = self._query(
            "select bq_find_one('things', '{}')".format(json.dumps({
                'color': 'blue',
                'n': {'$gt': 5},
            }))
        )
        self.assertEqual(result[0][0]['label'], 'd')

        result = self._query(
            "select bq_find_one('things', '{}')".format(json.dumps({
                'color': 'red',
                'n': {'$gt': 5},
            }))
        )
        self.assertEqual(result[0][0]['label'], 'c')

        result = self._query(
            "select bq_find_one('things', '{}')".format(json.dumps({
                'color': 'red',
                'n': {'$gte': 8},
            }))
        )
        self.assertEqual(result[0][0]['label'], 'c')

    def test_lt(self):
        rows = [
            {"_id": "aa", "label": "a", "n": 1,  "color": "red"},
            {"_id": "bb", "label": "b", "n": 4,  "color": "red"},
            {"_id": "cc", "label": "c", "n": 8,  "color": "red"},
            {"_id": "dd", "label": "d", "n": 16, "color": "blue"},
            {"_id": "ee", "label": "e", "n": 8,  "color": "blue"},
            {"_id": "ff", "label": "f", "n": 16, "color": "red"},
            {"_id": "dud", "color": "blue"}
        ]
        for row in rows:
            self._insert('things', row)

        # find_one
        result = self._query(
            "select bq_find_one('things', '{}')".format(json.dumps({
                'color': 'blue',
                'n': {'$lt': 10},
            }))
        )
        self.assertEqual(result[0][0]['label'], 'e')

        result = self._query(
            "select bq_find_one('things', '{}')".format(json.dumps({
                'color': 'red',
                'n': {'$lt': 2},
            }))
        )
        self.assertEqual(result[0][0]['label'], 'a')

        result = self._query(
            "select bq_find_one('things', '{}')".format(json.dumps({
                'color': 'blue',
                'n': {'$lte': 8},
            }))
        )
        self.assertEqual(result[0][0]['label'], 'e')

    def test_in(self):
        rows = [
            {"_id": "aa", "label": "a", "n": 1,  "color": "red"},
            {"_id": "bb", "label": "b", "n": 4,  "color": "red"},
            {"_id": "cc", "label": "c", "n": 8,  "color": "red"},
            {"_id": "dd", "label": "d", "n": 16, "color": "blue"},
            {"_id": "ee", "label": "e", "n": 8,  "color": "blue"},
            {"_id": "ff", "label": "f", "n": 16, "color": "red"},
            {"_id": "dud", "color": "blue"}
        ]
        for row in rows:
            self._insert('things', row)

        # find_one
        result = self._query(
            "select bq_find_one('things', '{}')".format(json.dumps({
                'color': 'red',
                'n': {'$in': [4, 22, 9]},
            }))
        )
        self.assertEqual(result[0][0]['label'], 'b')

        result = self._query(
            "select bq_find_one('things', '{}')".format(json.dumps({
                'color': 'blue',
                'n': {'$in': [2, 8, 24]},
            }))
        )
        self.assertEqual(result[0][0]['label'], 'e')
