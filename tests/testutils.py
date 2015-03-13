import psycopg2
import os
import getpass


def get_pg_connection():
    return psycopg2.connect(
        "dbname=bedquilt_test user={}".format(getpass.getuser())
    )
