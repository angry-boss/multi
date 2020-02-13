if defined?(JRUBY_VERSION)

  require 'spec_helper'
  require 'multi/adapters/jdbc_mysql_adapter'

  describe Multi::Adapters::JDBCMysqlAdapter, database: :mysql do

    subject { Multi::Tenant.jdbc_mysql_adapter config.symbolize_keys }

    def tenant_names
      ActiveRecord::Base.connection.execute("SELECT schema_name FROM information_schema.schemata").collect { |row| row['schema_name'] }
    end

    let(:default_tenant) { subject.switch { ActiveRecord::Base.connection.current_database } }

    it_should_behave_like "a generic multi adapter"
    it_should_behave_like "a connection based multi adapter"
  end
end
