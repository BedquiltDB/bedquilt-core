import testutils
import json
import psycopg2

class TestRemoveConstraints(testutils.BedquiltTestCase):

    def test_remove_required_constraint(self):
        tests = [
            ({'name': {'$required': True}}, {'derp': 1}),
            ({'name': {'$notNull': True}}, {'name': None}),
            ({'age': {'$type': 'number'}}, {'age': ['fish']})
        ]
        for constraint, example in tests:
            testutils.clean_database(self.conn)
            # remove constraint without even applying it
            result = self._query("""
            select bq_remove_constraint('things', '{}');
            """.format(json.dumps(constraint)))

            self.assertEqual(result, [(False,)])

            # add the constraint
            result = self._query("""
            select bq_add_constraint('things', '{}');
            """.format(json.dumps(constraint)))

            self.assertEqual(result, [(True,)])

            # example should fail to insert
            with self.assertRaises(psycopg2.IntegrityError):
                self.cur.execute("""
                select bq_insert('things', '{}');
                """.format(json.dumps(example)))
            self.conn.rollback()

            # remove the constraint
            result = self._query("""
            select bq_remove_constraint('things', '{}');
            """.format(json.dumps(constraint)))

            self.assertEqual(result, [(True,)])

            # remove again
            result = self._query("""
            select bq_remove_constraint('things', '{}');
            """.format(json.dumps(constraint)))

            self.assertEqual(result, [(False,)])

            # example should insert fine
            result = self._query("""
            select bq_insert('things', '{}')
            """.format(json.dumps(example)))

            self.assertIsNotNone(result)


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

    def test_basic_type_constraint(self):
        result = self._query("""
        select bq_add_constraint('things', '{}');
        """.format(json.dumps({
            'age': {'$type': 'number'}
        })))
        self.assertEqual(result, [(True,)])

        # should reject non-number fields for age
        for val in ['wat', [2], {'wat': 2}, False]:
            doc = {
                'age': val
            }
            with self.assertRaises(psycopg2.IntegrityError):
                self._query("""
                select bq_insert('things', '{}');
                """.format(json.dumps(doc)))
            self.conn.rollback()

        # should be ok if age is a number
        doc = {
            'age': 22
        }
        result = self._query("""
        select bq_insert('things', '{}')
        """.format(json.dumps(doc)))
        self.assertIsNotNone(result)

    def test_type_constraint_on_missing_value(self):
        result = self._query("""
        select bq_add_constraint('things', '{}');
        """.format(json.dumps({
            'age': {'$type': 'number'}
        })))
        self.assertEqual(result, [(True,)])

        # should be ok if the field is absent entirely
        doc = {
            'name': 'paul'
        }
        result = self._query("""
        select bq_insert('things', '{}')
        """.format(json.dumps(doc)))
        self.assertIsNotNone(result)
