require 'spec_helper'
require 'multi/adapters/postgresql_adapter'

describe Multi::Adapters::PostgresqlAdapter, database: :postgresql do
  unless defined?(JRUBY_VERSION)

    subject{ Multi::Tenant.postgresql_adapter config }

    context "using schemas with schema.rb" do

      before{ Multi.use_schemas = true }

      # Not sure why, but somehow using let(:tenant_names) memoizes for the whole example group, not just each test
      def tenant_names
        ActiveRecord::Base.connection.execute("SELECT nspname FROM pg_namespace;").collect { |row| row['nspname'] }
      end

      let(:default_tenant) { subject.switch { ActiveRecord::Base.connection.schema_search_path.gsub('"', '') } }

      it_should_behave_like "a generic multi adapter"
    end

    context "using schemas with SQL dump" do

      before{ Multi.use_schemas = true; Multi.use_sql = true }

      # Not sure why, but somehow using let(:tenant_names) memoizes for the whole example group, not just each test
      def tenant_names
        ActiveRecord::Base.connection.execute("SELECT nspname FROM pg_namespace;").collect { |row| row['nspname'] }
      end

      let(:default_tenant) { subject.switch { ActiveRecord::Base.connection.schema_search_path.gsub('"', '') } }

      it_should_behave_like "a generic multi adapter"

      it 'allows for dashes in the schema name' do
        expect { Multi::Tenant.create('has-dashes') }.to_not raise_error
      end

      after { Multi::Tenant.drop('has-dashes') if Multi.connection.schema_exists? 'has-dashes' }
    end

    context "using connections" do

      before{ Multi.use_schemas = false }

      # Not sure why, but somehow using let(:tenant_names) memoizes for the whole example group, not just each test
      def tenant_names
        connection.execute("select datname from pg_database;").collect { |row| row['datname'] }
      end

      let(:default_tenant) { subject.switch { ActiveRecord::Base.connection.current_database } }

      it_should_behave_like "a generic multi adapter"
    end
  end
end
