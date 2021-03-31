# email_proxy

A service acting as a proxy between emails that need to be sent and the various
providers we support. This initial version supports switching between two
providers, Snailgun and Spendgrid, via changing the environment variable
`ENV['EMAIL_PROXY_PROVIDER']`, and takes one of two values: `spendgrid` or
`snailgun`. If the environment variable is not set, then  Spendgrid will be
used by default.

## Install

`email_proxy` is a standard Rails application configured for API mode. It
consumes and returns JSON, and currently requires not authentication to send
emails.

### Database

#### Database as message queue

`email_proxy` uses a database as a message queue, and relies on PostgreSQL.
Check the `config/database.yml` file for the database names and roles. For local
development it is recommended that you give the `email_proxy` role the following
permissions:

* login
* createdb
* superuser

#### Setting up the DB role and starting databases

When the role is setup correctly for local dev, running `\dg` inside of `psql`
should should the following attributes:

```plaintext
# \dg

    Role name    |                         Attributes                         | Member of
-----------------+------------------------------------------------------------+-----------
 email_proxy     | Superuser, Create DB                                       | {}
```

Create the database using the normal rake commands: `db:create db:migrate`.
When that is complete, then running `\l` to list databases inside of `psql`
should show the development and test databases.

```plaintext
# \l
                                         List of databases
       Name       |      Owner      | Encoding |   Collate   |    Ctype    |   Access privileges
------------------+-----------------+----------+-------------+-------------+-----------------------
 email_proxy      | jlunt           | UTF8     | en_US.UTF-8 | en_US.UTF-8 |
 email_proxy_test | jlunt           | UTF8     | en_US.UTF-8 | en_US.UTF-8 |
```

#### Required PostgreSQL extensions

This service makes use of UUID `:id` fields for records. This requires the
`uuid-ossp` and `pgcrytpo` extensions be available in your PostgreSQL. This
service was tested against PostgreSQL 12.x, and should work with newer versions
as well.
