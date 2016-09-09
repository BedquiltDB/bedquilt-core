# Updating to a New Version of BedquiltDB

The BedquiltDB projects strives to preserve backwards-compatibility between releases, and trys to follow semver as much as possible. Where breaking changes are necessary, upgrade instructions will be published here.

## 2.0.0

- Bedquilt 2.0.0 requires the `plpython3u` language extension be installed on the PostgreSQL server
- Bedquilt now requires PostgreSQL version 9.5 or later
- The naming convention for internal utility functions has changed
- All public functions have been changed to accept `jsonb` parameters rather than `json`
- The `find_one` function now accepts `skip` and `sort` parameters
- Sort specifiers now include `$created` and `$updated` options
- Query operations now support [Advanced Query Operators](../spec.md#aside-advanced-query-operations)

Update process:

- Update to PostgreSQL 9.5
- Install the `plpython3u` language package for postgresql
- Install BedquiltDB 2
- Run the following SQL code:
```
create extension if not exists pgcrypto;
create extension if not exists plpython3u;
drop extension if exists bedquilt;
create extension bedquilt;
```
- Update client libraries to a version which supports BedquiltDB 2.0
