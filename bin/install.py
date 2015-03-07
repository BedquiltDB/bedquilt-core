#! /usr/bin/env python

# bedquilt installer script


import argparse
import subprocess
import os
import glob


SCRIPT_LOCATION = os.path.dirname(os.path.realpath(__file__))
SQL_DIR = os.path.realpath(os.path.join(SCRIPT_LOCATION, '../sql'))


BEDQUILT_MODULES = [
    'bootstrap.sql',
    'utilities.sql',
    'collection_ops.sql',
    'document_writes.sql',
    'document_reads.sql'
]


def get_sql_files():
    return map(lambda i: os.path.join(SQL_DIR, i),
               BEDQUILT_MODULES)


def main():
    parser = argparse.ArgumentParser(description='Bedquilt installer')
    parser.add_argument('--database',
                        dest='database',
                        metavar='database',
                        type=str,
                        nargs=1,
                        help='the database to install to')

    args = parser.parse_args()
    database = args.database[0]

    for sql_file in get_sql_files():
        print ">> Installing {0} to {1}".format(sql_file, database)
        subprocess.call(
            "psql {0} < {1}".format(database, sql_file),
            shell=True
        )


if __name__ == "__main__":
    main()
