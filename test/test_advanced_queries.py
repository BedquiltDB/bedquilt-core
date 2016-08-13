import testutils
import json
import psycopg2


class TestAdvancedQueries(testutils.BedquiltTestCase):

    def _map_labels(self, results):
        return list(map(lambda row: row[0]['label'], results))

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

        # find many
        result = self._query(
            "select bq_find('things', '{}')".format(json.dumps({
                'n': {'$eq': 8},
            }))
        )
        self.assertEqual(len(result), 2)
        self.assertEqual(self._map_labels(result), ['c', 'e'])

        result = self._query(
            "select bq_find('things', '{}')".format(json.dumps({
                'color': {'$eq': 'red'},
            }))
        )
        self.assertEqual(len(result), 4)
        self.assertEqual(self._map_labels(result), ['a', 'b', 'c', 'f'])

    def test_noteq(self):
        rows = [
            {"_id": "wat", "label": "oh", "color": "purple"},
            {"_id": "aa", "label": "a", "n": 1,  "color": "red"},
            {"_id": "bb", "label": "b", "n": 4,  "color": "red"},
            {"_id": "dud", "label": "dud", "color": "blue"}
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

        # find many
        result = self._query(
            "select bq_find('things', '{}')".format(json.dumps({
                'n': {'$noteq': 4},
            }))
        )
        self.assertEqual(len(result), 3)
        self.assertEqual(self._map_labels(result), ['oh', 'a', 'dud'])

        result = self._query(
            "select bq_find('things', '{}')".format(json.dumps({
                'n': {'$noteq': 400},
            }))
        )
        self.assertEqual(len(result), 4)
        self.assertEqual(self._map_labels(result), ['oh', 'a', 'b', 'dud'])

        result = self._query(
            "select bq_find('things', '{}')".format(json.dumps({
                'color': {'$noteq': 'red'},
            }))
        )
        self.assertEqual(len(result), 2)
        self.assertEqual(self._map_labels(result), ['oh', 'dud'])

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

        # find many
        result = self._query(
            "select bq_find('things', '{}')".format(json.dumps({
                'color': 'blue',
                'n': {'$gt': 5},
            }))
        )
        self.assertEqual(len(result), 2)
        self.assertEqual(self._map_labels(result), ['d', 'e'])

        result = self._query(
            "select bq_find('things', '{}')".format(json.dumps({
                'color': 'red',
                'n': {'$gte': 4},
            }))
        )
        self.assertEqual(len(result), 3)
        self.assertEqual(self._map_labels(result), ['b', 'c', 'f'])

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

        # find many
        result = self._query(
            "select bq_find('things', '{}')".format(json.dumps({
                'color': 'red',
                'n': {'$lt': 16},
            }))
        )
        self.assertEqual(len(result), 3)
        self.assertEqual(self._map_labels(result), ['a', 'b', 'c'])

        result = self._query(
            "select bq_find('things', '{}')".format(json.dumps({
                'color': 'red',
                'n': {'$lte': 16},
            }))
        )
        self.assertEqual(len(result), 4)
        self.assertEqual(self._map_labels(result), ['a', 'b', 'c', 'f'])

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

        # find many
        result = self._query(
            "select bq_find('things', '{}')".format(json.dumps({
                'color': 'red',
                'n': {'$in': [4, 2, 16, 9]},
            }))
        )
        self.assertEqual(len(result), 2)
        self.assertEqual(self._map_labels(result), ['b', 'f'])

    def test_notin(self):
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
                'n': {'$notin': [1, 8, 16]},
            }))
        )
        self.assertEqual(result[0][0]['label'], 'b')

        result = self._query(
            "select bq_find_one('things', '{}')".format(json.dumps({
                'color': 'blue',
                'n': {'$notin': [16, 12]},
            }))
        )
        self.assertEqual(result[0][0]['label'], 'e')

        # find many
        result = self._query(
            "select bq_find('things', '{}')".format(json.dumps({
                'color': 'red',
                'n': {'$notin': [22, 4, 8]},
            }))
        )
        self.assertEqual(len(result), 2)
        self.assertEqual(self._map_labels(result), ['a', 'f'])

    def test_exists(self):
        rows = [
            {"_id": "aa", "color": "red",  "label": "a", "nested": {"x": 42}},
            {"_id": "bb", "color": "blue", "label": "b"},
            {"_id": "cc", "color": "blue", "label": "c", "nested": {"x": 44}},
            {"_id": "dd", "color": "red",  "label": "d", "nested": {"y": 13}},
            {"_id": "ee", "color": "blue", "label": "e", "nested": {"x": 46}},
            {"_id": "ff", "color": "red",  "label": "f"},
            {"_id": "gg", "color": "blue", "label": "g"},
        ]
        for row in rows:
            self._insert('things', row)

        # exists=true, find one
        result = self._query(
            "select bq_find_one('things', '{}')".format(json.dumps({
                'color': 'blue',
                'nested': {
                    'x': {'$exists': True}
                },
            }))
        )
        self.assertEqual(result[0][0]['label'], 'c')

        # exists=true, find many
        result = self._query(
            "select bq_find('things', '{}')".format(json.dumps({
                'color': 'blue',
                'nested': {
                    'x': {'$exists': True}
                },
            }))
        )
        self.assertEqual(len(result), 2)
        self.assertEqual(self._map_labels(result), ['c', 'e'])

        # exists=false, find one
        result = self._query(
            "select bq_find_one('things', '{}')".format(json.dumps({
                'color': 'blue',
                'nested': {
                    'x': {'$exists': False}
                },
            }))
        )
        self.assertEqual(result[0][0]['label'], 'b')

        # exists=false, find many
        result = self._query(
            "select bq_find('things', '{}')".format(json.dumps({
                'color': 'blue',
                'nested': {
                    'x': {'$exists': False}
                },
            }))
        )
        self.assertEqual(len(result), 2)
        self.assertEqual(self._map_labels(result), ['b', 'g'])

    def test_type(self):
        rows = [
            {'label': 'a', 'x': 42},
            {'label': 'b', 'x': 'wat'},
            {'label': 'c', 'x': None},
            {'label': 'd', 'x': 90},
            {'label': 'e', 'x': True},
            {'label': 'f', 'x': 'wat'},
            {'label': 'g', 'x': [1, 2, 3]},
            {'label': 'h', 'x': {'foo': 'bar'}},
            {'label': 'i', 'x': [4, 5]},
            {'label': 'j', 'x': False},
            {'label': 'k', 'x': {'foo': 'baz'}},
            {'label': 'l', 'x': None},
            {'label': 'm', 'x': None}
        ]
        for row in rows:
            self._insert('things', row)

        # find one
        examples = [
            ('number',  'a'),
            ('string',  'b'),
            ('object',  'h'),
            ('array',   'g'),
            ('boolean', 'e'),
            ('null',    'c')
        ]
        for type_string, label in examples:
            result = self._query(
                "select bq_find_one('things', '{}')".format(json.dumps({
                    'x': {'$type': type_string}
                }))
            )
            self.assertEqual(result[0][0]['label'], label)

        # find many
        examples = [
            ('number',  ['a', 'd']),
            ('string',  ['b', 'f']),
            ('object',  ['h', 'k']),
            ('array',   ['g', 'i']),
            ('boolean', ['e', 'j']),
            ('null',    ['c', 'l', 'm'])
        ]
        for type_string, labels in examples:
            result = self._query(
                "select bq_find('things', '{}')".format(json.dumps({
                    'x': {'$type': type_string}
                }))
            )
            self.assertEqual(self._map_labels(result), labels)

    def test_like(self):
        rows = [
            {'label': 'a', 'x': 42},
            {'label': 'b', 'x': 'one two'},
            {'label': 'c', 'x': 'oh no two'},
            {'label': 'd', 'x': 90},
            {'label': 'e', 'x': True},
            {'label': 'f', 'x': 'three four'},
            {'label': 'g', 'x': 'nine four'},
        ]
        for row in rows:
            self._insert('things', row)

        examples = [
            ('%two',    'b'),
            ('%one%',   'b'),
            ('%four',   'f'),
            ('%ree f%', 'f')
        ]

        # find one
        for like_string, label in examples:
            result = self._query(
                "select bq_find_one('things', '{}')".format(json.dumps({
                    'x': {'$like': like_string}
                }))
            )
            self.assertEqual(result[0][0]['label'], label)

        # find many
        examples = [
            ('%two',    ['b', 'c']),
            ('%o%',     ['b','c','f', 'g']),
            ('%four',   ['f', 'g']),
            ('%ree f%', ['f'])
        ]
        for like_string, labels in examples:
            result = self._query(
                "select bq_find('things', '{}')".format(json.dumps({
                    'x': {'$like': like_string}
                }))
            )
            self.assertEqual(self._map_labels(result), labels)

    def test_regex(self):
        rows = [
            {'label': 'a', 'x': 42},
            {'label': 'b', 'x': 'one two'},
            {'label': 'c', 'x': 'oh no two'},
            {'label': 'd', 'x': 90},
            {'label': 'e', 'x': True},
            {'label': 'f', 'x': 'three four'},
            {'label': 'g', 'x': 'nine four'},
        ]
        for row in rows:
            self._insert('things', row)

        examples = [
            ('^.*two$',     'b'),
            ('^.*one.*$',   'b'),
            ('^.*four$',    'f'),
            ('^.*ree f.*$', 'f')
        ]

        # find one
        for regex_string, label in examples:
            result = self._query(
                "select bq_find_one('things', '{}')".format(json.dumps({
                    'x': {'$regex': regex_string}
                }))
            )
            self.assertEqual(result[0][0]['label'], label)

        # find many
        examples = [
            ('^.*two$',     ['b', 'c']),
            ('^.*o.*$',     ['b','c','f', 'g']),
            ('^.*four$',    ['f', 'g']),
            ('^.*ree f.*$', ['f'])
        ]
        for regex_string, labels in examples:
            result = self._query(
                "select bq_find('things', '{}')".format(json.dumps({
                    'x': {'$regex': regex_string}
                }))
            )
            self.assertEqual(self._map_labels(result), labels)
