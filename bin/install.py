#! /usr/bin/env python

# bedquilt installer script


import argparse
import subprocess
import os
import glob


SCRIPT_LOCATION = os.path.dirname(os.path.realpath(__file__))
SQL_DIR = os.path.realpath(os.path.join(SCRIPT_LOCATION, '../sql'))


def get_sql_files():
    return sorted(glob.glob(os.path.join(SQL_DIR, '*.sql')))


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

    files = get_sql_files()

    print "This does nothing yet"
    print SQL_DIR
    print "Database: ", database
    print files



if __name__ == "__main__":
    main()
