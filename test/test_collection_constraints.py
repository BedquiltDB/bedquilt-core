import testutils
import json
import psycopg2


class TestConstraints(testutils.BedquiltTestCase):

    def test_add_required_constraint(self):
        q = """
        select bq_add_constraint('things', '{}');
        """.format(json.dumps({'name': {'$required': True}}))
        result = self._query(q)

        self.assertEqual(result, [(True,)])

        # adding again should be false
        result = self._query(q)

        self.assertEqual(result, [(False,)])

        # should insist on the name field being present
        doc = {
            'derp': 1
        }
        with self.assertRaises(psycopg2.IntegrityError):
            self.cur.execute("""
            select bq_insert('things', '{}');
            """.format(json.dumps(doc)))
        self.conn.rollback()

        # should be fine with a name key
        doc = {
            'name': 'steve',
            'age': 24
        }
        result = self._query("""
        select bq_insert('things', '{}')
        """.format(json.dumps(doc)))
        self.assertIsNotNone(result)

        # should be fine with a name key, even null
        doc = {
            'name': None,
            'age': 24
        }
        result = self._query("""
        select bq_insert('things', '{}')
        """.format(json.dumps(doc)))

        self.assertIsNotNone(result)

    def test_notNull_constraint(self):
        result = self._query("""
        select bq_add_constraint('things', '{}');
        """.format(json.dumps({
            'name': {'$notNull': 1}
        })))
        self.assertEqual(result, [(True,)])

        # should reject doc with name missing
        doc = {
            'age': 24
        }
        with self.assertRaises(psycopg2.IntegrityError):
            self._query("""
            select bq_insert('things', '{}');
            """.format(json.dumps(doc)))
        self.conn.rollback()

        # should reject doc with name set to null
        doc = {
            'name': None,
            'age': 24
        }
        with self.assertRaises(psycopg2.IntegrityError):
            self._query("""
            select bq_insert('things', '{}');
            """.format(json.dumps(doc)))
        self.conn.rollback()

        # should be fine with a name key that is not null
        doc = {
            'name': 'steve',
            'age': 24
        }
        result = self._query("""
        select bq_insert('things', '{}')
        """.format(json.dumps(doc)))
        self.assertIsNotNone(result)
