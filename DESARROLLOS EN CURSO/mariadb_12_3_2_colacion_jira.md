# MariaDB 12.3.2: `DEFAULT CHARSET=utf8mb4` creates mixed-collation schemas

## Intended destination

- Project: `MDEV` (MariaDB Server).
- Component: Character Sets.
- Suggested issue type: Bug or compatibility/documentation issue.
- Related issue: [MDEV-38743 — Document the implications of changing the
  default collation](https://jira.mariadb.org/browse/MDEV-38743).
- Related implementation: [MDEV-25829 — Change default Unicode collation to
  uca1400_ai_ci](https://jira.mariadb.org/browse/MDEV-25829).

## Suggested title

`DEFAULT CHARSET=utf8mb4` can silently override the database collation and
produce production-blocking mixed-collation schemas

## Environment

```text
MariaDB version: 12.3.2-MariaDB
Version comment: MariaDB Server

character_set_collations:
utf8mb3=utf8mb3_uca1400_ai_ci,
ucs2=ucs2_uca1400_ai_ci,
utf8mb4=utf8mb4_uca1400_ai_ci,
utf16=utf16_uca1400_ai_ci,
utf32=utf32_uca1400_ai_ci

character_set_server:     utf8mb4
collation_server:         utf8mb4_uca1400_ai_ci
character_set_connection: utf8mb4
collation_connection:     utf8mb4_uca1400_ai_ci
```

Operating system: Windows. The problem is produced by the server and can be
reproduced using the standard MariaDB command-line client without the
application or its database driver.

## Summary

An existing application database uses `utf8mb4_spanish_ci`. Migration scripts
historically and commonly declare tables as follows:

```sql
CREATE TABLE example (...)
ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

On MariaDB 12.3.2, specifying `DEFAULT CHARSET=utf8mb4` without an explicit
`COLLATE` selects `utf8mb4_uca1400_ai_ci`, even when the database was explicitly
created with `utf8mb4_spanish_ci`.

This silently produces a schema in which old and new physical columns use
different collations. Comparisons between those columns then abort with error
1267 because both operands have `IMPLICIT` coercibility.

We understand that selecting the default collation of an explicitly specified
character set is documented behavior. The compatibility impact is nevertheless
severe: a DDL pattern that was safe and extremely common before the default
Unicode collation changed can now make essential production queries fail.

## Minimal reproducible example

The following script was executed successfully up to the final `SELECT` on
MariaDB 12.3.2. It does not require any application code.

```sql
DROP DATABASE IF EXISTS mdev_collation_repro;

SET NAMES utf8mb4;

CREATE DATABASE mdev_collation_repro
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_spanish_ci;

USE mdev_collation_repro;

SELECT DATABASE(),
       @@character_set_database,
       @@collation_database,
       @@character_set_connection,
       @@collation_connection;

CREATE TABLE physical_table (
    code VARCHAR(50)
);

CREATE TABLE charset_only_table (
    code VARCHAR(50)
) DEFAULT CHARSET=utf8mb4;

INSERT INTO physical_table VALUES ('TEST');
INSERT INTO charset_only_table VALUES ('TEST');

SELECT TABLE_NAME,
       TABLE_COLLATION
  FROM INFORMATION_SCHEMA.TABLES
 WHERE TABLE_SCHEMA = DATABASE()
   AND TABLE_TYPE = 'BASE TABLE'
 ORDER BY TABLE_NAME;

SELECT TABLE_NAME,
       COLUMN_NAME,
       CHARACTER_SET_NAME,
       COLLATION_NAME
  FROM INFORMATION_SCHEMA.COLUMNS
 WHERE TABLE_SCHEMA = DATABASE()
   AND TABLE_NAME IN ('physical_table', 'charset_only_table')
 ORDER BY TABLE_NAME, COLUMN_NAME;

SELECT physical.code,
       current_table.code
  FROM physical_table physical
  JOIN charset_only_table current_table
    ON current_table.code = physical.code;

DROP DATABASE mdev_collation_repro;
```

The cleanup statement must be executed separately after the failing `SELECT`
if the SQL client stops processing the script on the first error.

## Actual result

The database and connection values immediately after `USE` are:

```text
database:                 mdev_collation_repro
character_set_database:   utf8mb4
collation_database:       utf8mb4_spanish_ci
character_set_connection: utf8mb4
collation_connection:     utf8mb4_uca1400_ai_ci
```

The two tables receive different collations:

```text
+--------------------+-----------------------+
| TABLE_NAME         | TABLE_COLLATION       |
+--------------------+-----------------------+
| charset_only_table | utf8mb4_uca1400_ai_ci |
| physical_table     | utf8mb4_spanish_ci    |
+--------------------+-----------------------+
```

Their `code` columns receive the same respective collations:

```text
+--------------------+-------------+--------------------+-----------------------+
| TABLE_NAME         | COLUMN_NAME | CHARACTER_SET_NAME | COLLATION_NAME        |
+--------------------+-------------+--------------------+-----------------------+
| charset_only_table | code        | utf8mb4            | utf8mb4_uca1400_ai_ci |
| physical_table     | code        | utf8mb4            | utf8mb4_spanish_ci    |
+--------------------+-------------+--------------------+-----------------------+
```

The final join fails:

```text
ERROR 1267 (HY000): Illegal mix of collations
(utf8mb4_uca1400_ai_ci,IMPLICIT) and
(utf8mb4_spanish_ci,IMPLICIT) for operation '='
```

## Expected result from an upgrade-compatibility perspective

When a table specifies the same character set already configured as the
database default but does not specify another collation, users commonly expect
the database collation to remain effective.

At minimum, an upgrade or migration warning should make it prominent that:

```sql
CREATE TABLE inherited_table (...);
```

and:

```sql
CREATE TABLE charset_only_table (...)
DEFAULT CHARSET=utf8mb4;
```

can create tables with different collations inside the same database after the
default collation associated with `utf8mb4` changes.

## Production impact

The affected application database was explicitly configured as:

```text
character set: utf8mb4
collation:     utf8mb4_spanish_ci
```

The incident prevented essential queries from executing. It was not a sorting
difference or a cosmetic change: joins between physical columns aborted with
error 1267.

`SET NAMES utf8mb4 COLLATE utf8mb4_spanish_ci` does not repair comparisons
between already-created physical columns. Both column operands have `IMPLICIT`
coercibility, so neither collation wins.

Recovery required detecting every deviating textual column and executing
operations such as:

```sql
ALTER TABLE affected_table
  CONVERT TO CHARACTER SET utf8mb4
  COLLATE utf8mb4_spanish_ci;
```

These operations can rebuild tables, consume significant time and storage, and
require a maintenance window in a production environment.

## Evidence from the affected database

After recovery, direct inspection on MariaDB 12.3.2 showed:

- The database default is `utf8mb4_spanish_ci`.
- All 143 base tables are currently normalized to `utf8mb4_spanish_ci`.
- Selecting the database changes `@@collation_database` to
  `utf8mb4_spanish_ci`, but `@@collation_connection` remains
  `utf8mb4_uca1400_ai_ci`.
- Several derived columns in existing views retain the connection collation
  used when those views were created. This is a secondary migration hazard for
  literals, `CASE` expressions and `UNION` results, although the minimal example
  above deliberately demonstrates the production error using physical columns.

An earlier check of `@@collation_database` performed without selecting the
application database returned the server default. After executing `USE
factuzam`, MariaDB correctly reported `utf8mb4_spanish_ci`. Therefore, this
report does not claim that `CREATE DATABASE ... COLLATE` itself is ignored.

The demonstrated problem is the silent selection of the character set's new
default collation when table DDL repeats `DEFAULT CHARSET=utf8mb4` without an
explicit `COLLATE`.

## Workarounds applied

All table creation scripts have been changed to specify both attributes:

```sql
ENGINE=InnoDB
DEFAULT CHARSET=utf8mb4
COLLATE=utf8mb4_spanish_ci;
```

Existing databases are audited through `INFORMATION_SCHEMA.TABLES` and
`INFORMATION_SCHEMA.COLUMNS`. Deviating tables are converted explicitly.

The application also sets the connection collation after connecting:

```sql
SET NAMES utf8mb4 COLLATE utf8mb4_spanish_ci;
```

This protects literals, parameters and newly created derived objects, but it
cannot repair physical columns that were already created with another
collation.

## Requested improvement

We suggest one or more of the following:

1. Add a prominent compatibility warning to the upgrade documentation for the
   change to `uca1400_ai_ci`.
2. Explicitly highlight that `DEFAULT CHARSET=utf8mb4` can override an existing
   database collation when no table-level `COLLATE` is provided.
3. Provide a documented pre-upgrade audit query for mixed table and column
   collations.
4. Provide an official migration procedure for preserving the existing
   database collation.
5. Consider whether specifying the same charset as the database, without a
   collation, should continue inheriting the database collation or should at
   least generate a warning when it differs.
6. Document that `USE database_name` updates `collation_database` but does not
   align `collation_connection`, which can affect literals and stored view
   expressions created during imports.

## Suggested audit query

```sql
SELECT T.TABLE_NAME,
       T.TABLE_COLLATION,
       C.COLUMN_NAME,
       C.CHARACTER_SET_NAME,
       C.COLLATION_NAME
  FROM INFORMATION_SCHEMA.TABLES T
  JOIN INFORMATION_SCHEMA.COLUMNS C
    ON C.TABLE_SCHEMA = T.TABLE_SCHEMA
   AND C.TABLE_NAME = T.TABLE_NAME
 WHERE T.TABLE_SCHEMA = 'application_database'
   AND T.TABLE_TYPE = 'BASE TABLE'
   AND C.CHARACTER_SET_NAME IS NOT NULL
   AND (
        C.CHARACTER_SET_NAME <> 'utf8mb4'
        OR C.COLLATION_NAME <> 'utf8mb4_spanish_ci'
       )
 ORDER BY T.TABLE_NAME,
          C.ORDINAL_POSITION;
```

## Attachment

Attach the screenshot showing the final join and the complete error 1267. The
screenshot corresponds to the minimal mixed-physical-column comparison shown
above.
