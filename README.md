# email_proxy

A service acting as a proxy between emails that need to be sent and the various
providers we support. This initial version supports switching between two
providers, Snailgun and Spendgrid, via changing the environment variable
`ENV['EMAIL_PROXY_PROVIDER']`, and takes one of two values: `spendgrid` or
`snailgun`. If the environment variable is not set, then  Spendgrid will be
used by default.

## Install for local dev

`email_proxy` is a standard Rails application configured for API mode. It
consumes and returns JSON, and currently requires not authentication to send
emails.

* Clone the repo
* Create your database user according to the instructions in the **Datase**
  section
* `bundle install`
* `bundle exec rake db:create db:schema:load`

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

## Allowing more time

### System design

#### Failure points

The problem itself is curious. We're placing a proxy service in front of two
email sending services, both of which are probably highly available. This design
is likely to lead to a single-point of failure when our internal proxy service
goes down which will be worse than the 3rd party provider's outage. In my
experieince, home-rolled solutions like this are usually less reliable than
battle-harded 3rd party providers, even though it's definitely true that 3rd
parties have issues.

What I would do instead of building an internal web service is adopt something
like AWS SES, perhaps in combination with a durable message queue or use the
database as a message queue as this example does. Certainly if we're sending
millions of emails per day right now I wouldn't put this "built in 2 hours, what
could possible go wrong?" service in front of something that critical. :)

#### Database as message queue / scaling

I opted to use the DB to record outgoing messages. This might work for a while,
but without scaling the write performance of the database it's likely to fall
over with millions of emails sent per day. Alternatives might include:

* Inveting the time to scale the writes of the database, or look into AWS Aurora
  to see if its claims of elastic write performance might suit our needs.
* Split the sending workload across some logical geographical regions, so that,
  for example, emails being sent in the Western United States write to a DB
    that's specific to that, Eastern United States to a different DB, etc.
* Use a dedicated, durable message queue for writing records instead of a
  database.
* If we either don't need to keep local records of our email sending, OR our 3rd
  party email senders do that for us, then we might not even need a local
  database. We might be able to get away with making this service _just_ an HTTP
  endpoint that doesn't log anything outside of the Rails logs. That would
  certainly help with scaling since we wouldn't need to roundtrip to the DB.

Which direction I took (or maybe something not even on this list) would depend
on more specifics regarding the incoming traffic load on this email service, the
business/regulatory requirments around keeping logs and records, and any
time/money tradeoffs that might be present. For example, maybe we need to plan
to 5x our traffic over the next 12 months - if we have the business growth data
to back that up, then we'd probably split the effort into two approaches:

* What can we do now to get incremental performance gains?
* How do we address the larger design issue of sending a ton of emails like
this?
  * Do we split up the workload?
  * Do we get beefier servers?
  * Do we look at alternative providers that are both more reliable and can take
    the extra traffic?
  * Do we instead have each service within our stack make its own connection to
    the 3rd party provider(s) and handle failures locally? This would probably
    increase complexity in each application that needs to send emails, but it
    might remove this proxy email sending service's single-point of failure.

### Code changes

I knew 2 hours wasn't going to be enough to thoroughly cover everything, but as
an MVP that's manually tested, this is okayish.

* Would have added tests
  * Controller
    * Send `POST` to `/email` with good params
    * Send `POST` to `/email` with bad params, triggering the `422` case
    * Send `POST` to `/email` with bad params, triggering the `500` case
  * Model
    * Validations
    * Email sending methods
* Handle polling for emails from snailgun - right now I just record the status
  from snailgun (queued, sent, failed) and don't poll for an updated status
* Done some basic cleanup
  * Don't hard-code API keys
  * If we thought we were going to add more providers, I'd pull the email
    integration out into their own class/module, rather than have them in one
    method. I think the current implementation is simple enough that having them
    in a single method will make any changes rather simple for any maintainers
    in the near-term.

## Observations

Above all else, if I were presented with this business need I would first ask
these questions:

"Okay, so what's causing the outage with our 3rd party provider? Do they have
multi-region availability or multiple API endpoints that we're not taking
advantage of? What does our retry logic look like from our side of things -
could it be improved to better handle interruptions in 3rd party uptime? How do
we know (why are we confident) that we can build a proxy email sending service
that will be more reliable than either of these two major providers? Are we
really sure we want to inject another service into email sending? That sounds
like adding complexity and room for increased failure rates, rather than
decreased."

---

Introducing a new service to handle millions of requests per day, and have that
sit in front of two large, well-respected 3rd party providers is probably a bad
idea unless we've got evidence to support going this direction - which, maybe we
do have, who knows? Without that data, however, we're likely creating single
point of failure that will be worse than the outages of our providers.

The problem specification also doesn't cover things like what retry/failure
modes we should handle, if any. For example, once the default provider fails,
what should the application do to monitor when the 3rd party comes back up?

Applications that sit in the critical business path like this should not require
a reconfig + redeploy to change. The application is already detecting failures,
from the 3rd party APIs, and as such should automatically switch from one
provider to the other, and trigger an alert to the ops team so they can observe
whether we have rare, frequent, or constant issues with one provider or another.
Some better error-detection and self-healing/retry logic can go a long way to
keep our ops teams from having to put our fires that we might have started
ourselves.
