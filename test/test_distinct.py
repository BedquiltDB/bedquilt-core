import testutils
import json
import string
import psycopg2

# Test for collection.distinct operation

class TestCollectionDiscinct(testutils.BedquiltTestCase):

    def test_distinct_on_empty_collection(self):
        _ = self._query("select bq_create_collection('people');")
        result = self._query("""
        select bq_distinct('people', 'age');
        """)
        self.assertEqual(result, [])

    def test_distinct_on_non_existant_collection(self):
        result = self._query("""
        select bq_distinct('people', 'age');
        """)
        self.assertEqual(result, [])

    def test_distinct_with_a_few_documents(self):
        _ = self._query("select bq_create_collection('people');")

        docs = [
            {'name': 'Sarah', 'age': 22},
            {'name': 'Brian', 'age': 24},
            {'name': 'Mike', 'age': 30},
            {'name': 'Diane', 'age': 38},
            {'name': 'Peter', 'age': 30}
        ]
        for doc in docs:
            self._query("select bq_insert('people', '{}')".format(json.dumps(doc)))
        result = self._query("""
        select bq_distinct('people', 'age');
        """)
        ages = sorted(map(lambda x: x[0], result))
        self.assertEqual(ages, sorted([22, 24, 30, 38]))

    def test_distinct_with_missing_values(self):
        _ = self._query("select bq_create_collection('people');")

        docs = [
            {'name': 'Sarah', 'age': 22},
            {'name': 'Brian'},
            {'name': 'Mike', 'age': 30},
            {'name': 'Diane', 'age': 38},
            {'name': 'Peter', 'age': 30}
        ]
        for doc in docs:
            self._query("select bq_insert('people', '{}')".format(json.dumps(doc)))
        result = self._query("""
        select bq_distinct('people', 'age');
        """)
        ages = sorted(map(lambda x: x[0], result))
        self.assertEqual(ages, sorted([22, 30, 38, None]))

    def test_distinct_on_dotted_path(self):
        _ = self._query("select bq_create_collection('people');")

        docs = [
            {'name': 'Sarah', 'address': {'city': 'Edinburgh'}},
            {'name': 'Brian', 'address': {'city': 'London'}},
            {'name': 'Mike', 'address': {'city': 'Edinburgh'}},
            {'name': 'Diane', 'address': {'city': 'Manchester'}},
            {'name': 'Peter', 'address': {'city': 'Edinburgh'}}
        ]
        for doc in docs:
            self._query("select bq_insert('people', '{}')".format(json.dumps(doc)))

        result = self._query("""
        select bq_distinct('people', 'address.city');
        """)
        cities = sorted(map(lambda x: x[0], result))
        self.assertEqual(cities, sorted(['Edinburgh', 'London', 'Manchester']))
