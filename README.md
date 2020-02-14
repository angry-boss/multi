<<<<<<< HEAD
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
=======
# Multi-tenancy
Config:

Create initializer file.
``config/initializers/multi.rb``

Put into file

``
require_relative '../lib/multi_tenancy/multi/logic/subdomain'

Multi.configure do |config|
  config.middleware.use Multi::Logic::Subdomain
>>>>>>> 32fffcbe59dba4c95eba98a30b7925682dcf8e58
end
``

<<<<<<< HEAD
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
=======
Then,

1. Create
`lib/tasks/db_enhancements.rake`

Put into file

``                      
>>>>>>> 32fffcbe59dba4c95eba98a30b7925682dcf8e58

namespace :db do
  desc 'Also create shared_extensions Schema'
  task :extensions => :environment  do
    # Create Schema
    ActiveRecord::Base.connection.execute 'CREATE SCHEMA IF NOT EXISTS shared_extensions;'
    # Enable Hstore
    ActiveRecord::Base.connection.execute 'CREATE EXTENSION IF NOT EXISTS HSTORE SCHEMA shared_extensions;'
    # Enable UUID-OSSP
    ActiveRecord::Base.connection.execute 'CREATE EXTENSION IF NOT EXISTS "uuid-ossp" SCHEMA shared_extensions;'
    # Enable pgcrypto
    ActiveRecord::Base.connection.execute 'CREATE EXTENSION IF NOT EXISTS  "pgcrypto" SCHEMA shared_extensions;'
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

``

2. Drop database, Create new, Run task, Make migration
`` rake db:drop
   rake db:create
   rake db:extensions
   rake db:migrate
``
3. Add extensions into database.yml
``
```yaml
# database.yml
...
adapter: postgresql
schema_search_path: "public,shared_extensions"
...
```
4. and now
```ruby
# config/initializers/multi.rb
...
config.persistent_schemas = ['shared_extensions']
...
```

## Usage

to create a new tenant, run the following command:

```ruby
Multi::Tenant.create('tenant_name')
```
### Switching Tenants

To switch tenants using Multi, use the following command:

```ruby
Multi::Tenant.switch('tenant_name') do
  # ...
end
```
To return to the default tenant, call `switch` with no arguments.

### Switching Tenants per request

Multi is Rack middleware.
Multi::Logic::Subdomain switch on your record and routing to your data.

to exclude a domain, for example www like a subdomain, in an initializer set the following:

```ruby
# config/initializers/multi.rb
Multi::Logic::Subdomain.excluded_subdomains = ['www']
```


#### Middleware Considerations

In the examples above, we show the Apartment middleware being appended to the Rack stack with

```ruby
Rails.application.config.middleware.use Multi::Logic::Subdomain
```
important to consider that you may want to maintain the "selected" tenant through different parts of the Rack application stack. For example, devise, gem adds the `Warden::Manager` middleware at the end of the stack in the examples above, our `Apartment::Elevators::Subdomain` middleware would come after it. Trouble is, Multi resets the selected tenant and redirects authentication in context of the "public" tenant.
To resolve this issue:

```ruby
Rails.application.config.middleware.insert_before Warden::Manager, Multi::Logic::Subdomain
```

To drop tenants:

```ruby
Multi::Tenant.drop('tenant_name')
```

schema is dropped and all data from itself

### Excluding models

```ruby
config.excluded_models = ["User", "Company"]        # these models will not be multi-tenanted, but remain in the global (public) namespace
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

This just invokes `Multi::Tenant.migrate(#{tenant_name})`

disable default migrating of all tenants with `db:migrate`
`Multi.db_migrate_tenants = false` in your `Rakefile`.
`Nlmt::Application.load_tasks`

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
  }
}
# or using a lambda:
config.tenant_names = lambda do
  Tenant.all.each_with_object({}) do |tenant, hash|
    hash[tenant.name] = tenant.db_configuration
  end
end
```

## Callbacks

execute callbacks when switching between tenants or creating a new one:

- before_create
- after_create
- before_switch
- after_switch

You can register a callback using [ActiveSupport::Callbacks](https://api.rubyonrails.org/classes/ActiveSupport/Callbacks.html) the following way:

```ruby
require 'multi/adapters/abstract_adapter'

module Multi
  module Adapters
    class AbstractAdapter
      set_callback :switch, :before do |object|
        ...
      end
    end
  end
end
```
<<<<<<< HEAD
=======

## Tests

* Rake tasks (in multi-tenancy) setup dbs for tests
>>>>>>> 32fffcbe59dba4c95eba98a30b7925682dcf8e58
