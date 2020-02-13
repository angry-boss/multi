module Multi
  module Adapters
    class AbstractAdapter
      include ActiveSupport::Callbacks
      define_callbacks :create, :switch

      attr_writer :default_tenant
      #   @param {Hash} config Database config
      def initialize(config)
        @config = config
      end

      #   Create a tenant, import schema, seed
      #   @param {String} tenant name
      def create(tenant)
        run_callbacks :create do
          create_tenant(tenant)

          switch(tenant) do
            import_database_schema

            seed_data if Multi.seed_after_create

            yield if block_given?
          end
        end
      end

      def current
        Multi.connection.current_database
      end

      #   public tenant  name
      def default_tenant
        @default_tenant || Multi.default_tenant
      end
      alias :default_schema :default_tenant

      def drop(tenant)
        with_neutral_connection(tenant) do |conn|
          drop_command(conn, tenant)
        end

      rescue *rescuable_exceptions => exception
        raise_drop_tenant_error!(tenant, exception)
      end

      def switch!(tenant = nil)
        run_callbacks :switch do
          return reset if tenant.nil?

          connect_to_new(tenant).tap do
            Multi.connection.clear_query_cache
          end
        end
      end

      def switch(tenant = nil)
        begin
          previous_tenant = current
          switch!(tenant)
          yield

        ensure
          switch!(previous_tenant) rescue reset
        end
      end

      #   to iterate
      def each(tenants = Multi.tenant_names)
        tenants.each do |tenant|
          switch(tenant){ yield tenant }
        end
      end

      #   new connection for excluded model
      def process_excluded_models
        Multi.excluded_models.each do |excluded_model|
          process_excluded_model(excluded_model)
        end
      end

      def reset
        Multi.establish_connection @config
      end

      #   seed file into the db
      def seed_data
        silence_warnings{ load_or_raise(Multi.seed_data_file) } if Multi.seed_data_file
      end
      alias_method :seed, :seed_data

      #   environment
      def environmentify(tenant)
        unless tenant.include?(Rails.env)
          if Multi.prepend_environment
            "#{Rails.env}_#{tenant}"
          elsif Multi.append_environment
            "#{tenant}_#{Rails.env}"
          else
            tenant
          end
        else
          tenant
        end
      end

    protected

      def process_excluded_model(excluded_model)
        excluded_model.constantize.establish_connection @config
      end

      def drop_command(conn, tenant)
        conn.execute("DROP DATABASE #{conn.quote_table_name(environmentify(tenant))}")
      end

      def create_tenant(tenant)
        with_neutral_connection(tenant) do |conn|
          create_tenant_command(conn, tenant)
        end
      rescue *rescuable_exceptions => exception
        raise_create_tenant_error!(tenant, exception)
      end

      def create_tenant_command(conn, tenant)
        conn.create_database(environmentify(tenant), @config)
      end

      def connect_to_new(tenant)
        query_cache_enabled = ActiveRecord::Base.connection.query_cache_enabled

        Multi.establish_connection multi_tenantify(tenant)
        Multi.connection.active?   # call active? to manually check if this connection is valid

        Multi.connection.enable_query_cache! if query_cache_enabled
      rescue *rescuable_exceptions => exception
        Multi::Tenant.reset if reset_on_connection_exception?
        raise_connect_error!(tenant, exception)
      end

      def import_database_schema
        ActiveRecord::Schema.verbose = false

        load_or_raise(Multi.database_schema_file) if Multi.database_schema_file
      end

      def multi_tenantify(tenant, with_database = true)
        db_connection_config(tenant).tap do |config|
          if with_database
            multi_tenantify_with_tenant_db_name(config, tenant)
          end
        end
      end

      def multi_tenantify_with_tenant_db_name(config, tenant)
        config[:database] = environmentify(tenant)
      end


      def load_or_raise(file)
        if File.exists?(file)
          load(file)
        else
          raise FileNotFound, "#{file} doesn't exist yet"
        end
      end
      # Backward compatibility
      alias_method :load_or_abort, :load_or_raise

      #   Exceptions to rescue from on db operations
      #
      def rescuable_exceptions
        [ActiveRecord::ActiveRecordError] + Array(rescue_from)
      end

      #   Extra exceptions to rescue from
      #
      def rescue_from
        []
      end

      def db_connection_config(tenant)
        Multi.db_config_for(tenant).clone
      end

     def with_neutral_connection(tenant, &block)
        if Multi.with_multi_server_setup
          # neutral connection is necessary whenever you need to create/remove a database from a server.
          # example: when you use postgresql, you need to connect to the default postgresql database before you create your own.
          SeparateDbConnectionHandler.establish_connection(multi_tenantify(tenant, false))
          yield(SeparateDbConnectionHandler.connection)
          SeparateDbConnectionHandler.connection.close
        else
          yield(Multi.connection)
        end
      end

      def reset_on_connection_exception?
        false
      end

      def raise_drop_tenant_error!(tenant, exception)
        raise TenantNotFound, "Error while dropping tenant #{environmentify(tenant)}: #{ exception.message }"
      end

      def raise_create_tenant_error!(tenant, exception)
        raise TenantExists, "Error while creating tenant #{environmentify(tenant)}: #{ exception.message }"
      end

      def raise_connect_error!(tenant, exception)
        raise TenantNotFound, "Error while connecting to tenant #{environmentify(tenant)}: #{ exception.message }"
      end

      class SeparateDbConnectionHandler < ::ActiveRecord::Base
      end
    end
  end
end
