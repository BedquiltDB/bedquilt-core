# Bedquilt

![Bedquilt](./resources/bedquilt_logo_tile.png)

A JSON store on PostgreSQL.


# Warning

Bedquilt is currently worse-than-alpha quality and should not be used in production,
or anywher else for that matter. If Bedquilt kills your database, just imagine me
whispering "told you so" and think hard about how you got yourself into this
mess.


# Installation

Run the `bin/install.py` script as a user with permisson to alter the database;
for example:

```bash
su postgres -c './bin/install.py --database some_db'
```


# Tests

Run `bin/run-tests.sh` to run the test suite. Requires a `bedquilt_test` database
that the current user owns.
