import psycopg2
import os
import getpass
import unittest


# CREATE DATABASE bedquilt_test
#   WITH OWNER = {{owner}}
#        ENCODING = 'UTF8'
#        TABLESPACE = pg_default
#        LC_COLLATE = 'en_GB.UTF-8'
#        LC_CTYPE = 'en_GB.UTF-8'
#        CONNECTION LIMIT = -1;


def get_pg_connection():
    return psycopg2.connect(
        database='bedquilt_test',
        user=getpass.getuser()
    )
PG_CONN  = get_pg_connection()


def clean_database(conn):
    cur = conn.cursor()
    cur.execute("select bq_list_collections();")
    result = cur.fetchall()
    if result is not None:
        for collection in result:
            cur.execute(
                "select bq_delete_collection('{}')".format(collection[0]))


class BedquiltTestCase(unittest.TestCase):

    def setUp(self):
        self.conn = PG_CONN
        self.cur = self.conn.cursor()
        clean_database(self.conn)
