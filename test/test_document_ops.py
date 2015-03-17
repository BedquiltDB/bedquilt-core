import testutils
import json


class TestInsertDocument(testutils.BedquiltTestCase):

    def test_insert_into_non_existant_collection(self):
        # create a collection 'testone'
        self.cur.execute("""
        select bq_insert_document('people', '{}');
        """.format(json.dumps({"_id": "user@example.com",
                               "name": "Some User",
                               "age": 20})))
        result = self.cur.fetchone()
        print result

        self.assertEqual(
            result, ("user@example.com",)
        )

        self.cur.execute("select bq_list_collections();")
        collections = self.cur.fetchall()
        self.assertIsNotNone(collections)

        self.assertEqual(collections, [("people",)])
