# Multi-tenancy
Config:

Create initializer file.
``config/initializers/multi.rb``

Put into file

``
require_relative '../lib/multi_tenancy/multi/logic/subdomain'

Multi.configure do |config|
  config.middleware.use Multi::Logic::Subdomain
end
``

Then,

1. Create
`lib/tasks/db_enhancements.rake`

Put into file
``
# This task should be run AFTER db:create but  
# BEFORE db:migrate.                        

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

## Tests

* Rake tasks (in multi-tenancy) setup dbs for tests
