### Video Tutorial

How to separate your application data into different accounts or companies.
[GoRails #47](https://gorails.com/episodes/multitenancy-with-apartment)

### Creating new Tenants

```ruby
Multi::Tenant.create('tenant_name')
```

If you're using the [prepend environment](https://github.com/influitive/apartment#handling-environments) config option or you AREN'T using Postgresql Schemas, this will create a tenant in the following format: "#{environment}\_tenant_name".
In the case of a sqlite database, this will be created in your 'db/' folder. With
other databases, the tenant will be created as a new DB within the system.

When you create a new tenant, all migrations will be run against that tenant, so it will be
up to date when create returns.

#### Notes on PostgreSQL

PostgreSQL works slightly differently than other databases when creating a new tenant. If you
are using PostgreSQL, Apartment by default will set up a new [schema](http://www.postgresql.org/docs/9.3/static/ddl-schemas.html)
and migrate into there. This provides better performance, and allows Apartment to work on systems like Heroku, which
would not allow a full new database to be created.

One can optionally use the full database creation instead if they want, though this is not recommended

### Switching Tenants

To switch tenants using Apartment, use the following command:

```ruby
Apartment::Tenant.switch('tenant_name') do
  # ...
end
```

When switch is called, all requests coming to ActiveRecord will be routed to the tenant you specify.

### Switching Tenants per request

You can have Apartment route to the appropriate tenant by adding some Rack middleware.
```ruby
# config/application.rb
require 'multi/logic/subdomain'
```
#### Switch on subdomain

In house, we use the subdomain elevator, which analyzes the subdomain of the request and switches to a tenant schema of the same name. It can be used like so:

```ruby
# application.rb
module MyApplication
  class Application < Rails::Application
    config.middleware.use Multi::Logic::Subdomain
  end
end
```

to exclude a domain
```ruby
# config/initializers/multi/subdomain_exclusions.rb
Multi::Logic::Subdomain.excluded_subdomains = ['www']
```

#### Middleware Considerations

```ruby
Rails.application.config.middleware.use Multi::Logic::Subdomain
```

### Dropping Tenants

To drop tenants using Apartment, use the following command:

```ruby
Multi::Tenant.drop('tenant_name')
```
When method is called, the schema is dropped and all data from itself will be lost.

## Config

config/initializers/apartment.rb

To set config options, add this to your initializer:

```ruby
Apartment.configure do |config|
  # set your options (described below) here
end
```

### Excluding models

If you have some models that should always access the 'public' tenant, you can specify this by configuring Apartment using `Multi.configure`. This will yield a config object for you. You can set excluded models like so:

```ruby
config.excluded_models = ["User", "Company"]        # remain in the global (public) namespace
```

### Postgresql Schemas

## Providing a Different default_schema

By default, ActiveRecord will use `"$user", public` as the default `schema_search_path`.

```ruby
config.default_schema = "some_other_schema"
```

all excluded models will use this schema as the table name prefix instead of `public` and `reset` on `Multi::Tenant`

## Persistent Schemas
 Enter `persistent_schemas`. configure a list of other schemas that will always remain in the search path

```ruby
config.persistent_schemas = ['some', 'other', 'schemas']
```

### Installing Extensions into Persistent Schemas

Persistent Schemas have numerous useful applications.  [Hstore](http://www.postgresql.org/docs/9.1/static/hstore.html), for instance, is a popular storage engine for Postgresql. In order to use extensions such as Hstore, you have to install it to a specific schema and have that always in the `schema_search_path`.

When using extensions, keep in mind:
* Extensions can only be installed into one schema per database, so we will want to install it into a schema that is always available in the `schema_search_path`
* The schema and extension need to be created in the database *before* they are referenced in migrations, database.yml or apartment.
* There does not seem to be a way to create the schema and extension using standard rails migrations.
* Rails db:test:prepare deletes and recreates the database, so it needs to be easy for the extension schema to be recreated here.

#### 1. Ensure the extensions schema is created when the database is created

```ruby
# lib/tasks/db_enhancements.rake

####### Important information ####################
# This file is used to setup a shared extensions #
# within a dedicated schema. This gives us the   #
# advantage of only needing to enable extensions #
# in one place.                                  #
#                                                #
# This task should be run AFTER db:create but    #
# BEFORE db:migrate.                             #
##################################################

namespace :db do
  desc 'Also create shared_extensions Schema'
  task :extensions => :environment  do
    # Create Schema
    ActiveRecord::Base.connection.execute 'CREATE SCHEMA IF NOT EXISTS shared_extensions;'
    # Enable Hstore
    ActiveRecord::Base.connection.execute 'CREATE EXTENSION IF NOT EXISTS HSTORE SCHEMA shared_extensions;'
    # Enable UUID-OSSP
    ActiveRecord::Base.connection.execute 'CREATE EXTENSION IF NOT EXISTS "uuid-ossp" SCHEMA shared_extensions;'
    # Grant usage to public
    ActiveRecord::Base.connection.execute 'GRANT usage ON SCHEMA shared_extensions to public;'
  end
end

Rake::Task["db:create"].enhance do
  Rake::Task["db:extensions"].invoke
end

Rake::Task["db:test:purge"].enhance do
  Rake::Task["db:extensions"].invoke
end
```

#### 2. Ensure the schema is in Rails' default connection

Next, your `database.yml` file must mimic what you've set for your default and persistent schemas in Apartment. When you run migrations with Rails, it won't know about the extensions schema because Apartment isn't injected into the default connection, it's done on a per-request basis, therefore Rails doesn't know about `hstore` or `uuid-ossp` during migrations.  To do so, add the following to your `database.yml` for all environments

```yaml
# database.yml
...
adapter: postgresql
schema_search_path: "public,shared_extensions"
...
```

This would be for a config with `default_schema` set to `public` and `persistent_schemas` set to `['shared_extensions']`. **Note**: This only works on Heroku with [Rails 4.1+](https://devcenter.heroku.com/changelog-items/426). For apps that use older Rails versions hosted on Heroku, the only way to properly setup is to start with a fresh PostgreSQL instance:

1. Append `?schema_search_path=public,hstore` to your `DATABASE_URL` environment variable, by this you don't have to revise the `database.yml` file (which is impossible since Heroku regenerates a completely different and immutable `database.yml` of its own on each deploy)
2. Run `heroku pg:psql` from your command line
3. And then `DROP EXTENSION hstore;` (**Note:** This will drop all columns that use `hstore` type, so proceed with caution; only do this with a fresh PostgreSQL instance)
4. Next: `CREATE SCHEMA IF NOT EXISTS hstore;`
5. Finally: `CREATE EXTENSION IF NOT EXISTS hstore SCHEMA hstore;` and hit enter (`\q` to exit)

To double check, login to the console of your Heroku app and see if `Apartment.connection.schema_search_path` is `public,hstore`

#### 3. Ensure the schema is in the apartment config

```ruby
# config/initializers/apartment.rb
...
config.persistent_schemas = ['shared_extensions']
...
```

#### Alternative: Creating schema by default

Another way that we've successfully configured hstore for our applications is to add it into the
postgresql template1 database so that every tenant that gets created has it by default.

One caveat with this approach is that it can interfere with other projects in development using the same extensions and template, but not using apartment with this approach.

You can do so using a command like so

```bash
psql -U postgres -d template1 -c "CREATE SCHEMA shared_extensions AUTHORIZATION some_username;"
psql -U postgres -d template1 -c "CREATE EXTENSION IF NOT EXISTS hstore SCHEMA shared_extensions;"
```

The *ideal* setup would actually be to install `hstore` into the `public` schema and leave the public
schema in the `search_path` at all times. We won't be able to do this though until public doesn't
also contain the tenanted tables, which is an open issue with no real milestone to be completed.
Happy to accept PR's on the matter.

#### Alternative: Creating new schemas by using raw SQL dumps

Apartment can be forced to use raw SQL dumps insted of `schema.rb` for creating new schemas. Use this when you are using some extra features in postgres that can't be represented in `schema.rb`, like materialized views etc.

This only applies while using postgres adapter and `config.use_schemas` is set to `true`.
(Note: this option doesn't use `db/structure.sql`, it creates SQL dump by executing `pg_dump`)

Enable this option with:
```ruby
config.use_sql = true
```

### Managing Migrations

In order to migrate all of your tenants (or postgresql schemas) you need to provide a list
of dbs to Apartment. You can make this dynamic by providing a Proc object to be called on migrations.
This object should yield an array of string representing each tenant name. Example:

```ruby
# Dynamically get tenant names to migrate
config.tenant_names = lambda{ Customer.pluck(:tenant_name) }

# Use a static list of tenant names for migrate
config.tenant_names = ['tenant1', 'tenant2']
```

You can then migrate your tenants using the normal rake task:

```ruby
rake db:migrate
```

This just invokes `Apartment::Tenant.migrate(#{tenant_name})` for each tenant name supplied
from `Apartment.tenant_names`

Note that you can disable the default migrating of all tenants with `db:migrate` by setting
`Apartment.db_migrate_tenants = false` in your `Rakefile`. Note this must be done
*before* the rake tasks are loaded. ie. before `YourApp::Application.load_tasks` is called

#### Parallel Migrations

Apartment supports parallelizing migrations into multiple threads when
you have a large number of tenants. By default, parallel migrations is
turned off. You can enable this by setting `parallel_migration_threads` to
the number of threads you want to use in your initializer.

Keep in mind that because migrations are going to access the database,
the number of threads indicated here should be less than the pool size
that Rails will use to connect to your database.

### Handling Environments

By default, when not using postgresql schemas, Apartment will prepend the environment to the tenant name
to ensure there is no conflict between your environments. This is mainly for the benefit of your development
and test environments. If you wish to turn this option off in production, you could do something like:

```ruby
config.prepend_environment = !Rails.env.production?
```

## Tenants on different servers

You can store your tenants in different databases on one or more servers.
To do it, specify your `tenant_names` as a hash, keys being the actual tenant names,
values being a hash with the database configuration to use.

Example:

```ruby
config.with_multi_server_setup = true
config.tenant_names = {
  'tenant1' => {
    adapter: 'postgresql',
    host: 'some_server',
    port: 5555,
    database: 'postgres' # this is not the name of the tenant's db
                         # but the name of the database to connect to, before creating the tenant's db
                         # mandatory in postgresql
  }
}
# or using a lambda:
config.tenant_names = lambda do
  Tenant.all.each_with_object({}) do |tenant, hash|
    hash[tenant.name] = tenant.db_configuration
  end
end
```

## Background workers

See [apartment-sidekiq](https://github.com/influitive/apartment-sidekiq) or [apartment-activejob](https://github.com/influitive/apartment-activejob).

## Callbacks

You can execute callbacks when switching between tenants or creating a new one, Apartment provides the following callbacks:

- before_create
- after_create
- before_switch
- after_switch

You can register a callback using [ActiveSupport::Callbacks](https://api.rubyonrails.org/classes/ActiveSupport/Callbacks.html) the following way:

```ruby
require 'apartment/adapters/abstract_adapter'

module Apartment
  module Adapters
    class AbstractAdapter
      set_callback :switch, :before do |object|
        ...
      end
    end
  end
end
```
