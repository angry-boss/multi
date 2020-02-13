require 'rails'
require 'multi/tenant'
require 'multi/reloader'

module Multi
  class Railtie < Rails::Railtie
    #   Set up our default config options
    #   Do this before the app initializers run so we don't override custom settings
    config.before_initialize do
      Multi.configure do |config|
        config.excluded_models = []
        config.use_schemas = true
        config.tenant_names = []
        config.seed_after_create = false
        config.prepend_environment = false
        config.append_environment = false
      end

      ActiveRecord::Migrator.migrations_paths = Rails.application.paths['db/migrate'].to_a
    end

    #   Hook into ActionDispatch::Reloader to ensure Multi is properly initialized
    config.to_prepare do
      next if ARGV.any? { |arg| arg =~ /\Aassets:(?:precompile|clean)\z/ }

      begin
        Multi.connection_class.connection_pool.with_connection do
          Multi::Tenant.init
        end
      rescue ::ActiveRecord::NoDatabaseError
        # Since `db:create` and other tasks invoke this block from Rails 5.2.0,
        # we need to swallow the error to execute `db:create` properly.
      end
    end
    #   Ensure rake tasks are loaded
    rake_tasks do
      load 'tasks/multi.rake'
      require 'multi/tasks/enhancements' if Multi.db_migrate_tenants
    end

    #   The following initializers for any environment where cache_classes is false, p.s. development
    if Rails.env.development?

      # Multi::Reloader is middleware to initialize on each request to dev
      initializer 'multi.init' do |app|
        app.config.middleware.use Multi::Reloader
      end

      # to call Multi::Tenant.init
      console do
        require 'multi/console'
      end
    end
  end
end
