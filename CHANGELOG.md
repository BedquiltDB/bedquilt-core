# BedquiltDB Changelog

## 2.1.0

Released 2016-09-13

- Remove `SECURITY DEFINER` specifier from collection ops, all operations are now performed
  with the permissions of the connected database user.


## 2.0.0

Released 2016-09-12

- Advanced Query Operators
- Add `skip` and `sort` options for `find_one`
- New `remove_many_by_ids` operation
- Add `$created` and `$updated` sorts
- Add `_util_` to names of utility functions


## 0.6.0

Released 2016-02-19

- Add `find_many_by_ids` function


## 0.5.0

Released 2015-11-22

- Add `bq_distinct` function


## 0.4.0

Released 2015-11-01

- Add skip, limit and sort options to `find` queries.


## 0.3.1

Released 2015-07-26

- Make `save` operations faster
- Change how constraint internals work:


## 0.3.0

Released 2015-07-01

- Constraints API


## 0.2.0

Released 2015-05-26

- Various bugfixes
