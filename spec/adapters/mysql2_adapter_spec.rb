require 'spec_helper'
require 'multi/adapters/mysql2_adapter'

describe Multi::Adapters::Mysql2Adapter, database: :mysql do
  unless defined?(JRUBY_VERSION)

    subject(:adapter){ Multi::Tenant.mysql2_adapter config }

    def tenant_names
      ActiveRecord::Base.connection.execute("SELECT schema_name FROM information_schema.schemata").collect { |row| row[0] }
    end

    let(:default_tenant) { subject.switch { ActiveRecord::Base.connection.current_database } }

    context "using - the equivalent of - schemas" do
      before { Multi.use_schemas = true }

      it_should_behave_like "a generic multi adapter"

      describe "#default_tenant" do
        it "is set to the original db from config" do
          expect(subject.default_tenant).to eq(config[:database])
        end
      end

      describe "#init" do
        include Multi::Spec::AdapterRequirements

        before do
          Multi.configure do |config|
            config.excluded_models = ["Company"]
          end
        end

        after do
          # Apartment::Tenant.init creates per model connection.
          # Remove the connection after testing not to unintentionally keep the connection across tests.
          Multi.excluded_models.each do |excluded_model|
            excluded_model.constantize.remove_connection
          end
        end

        it "should process model exclusions" do
          Multi::Tenant.init

          expect(Company.table_name).to eq("#{default_tenant}.companies")
        end
      end
    end

    context "using connections" do
      before { Multi.use_schemas = false }

      it_should_behave_like "a generic multi adapter"
      it_should_behave_like "a generic multi adapter able to handle custom configuration"
      it_should_behave_like "a connection based multi adapter"
    end
  end
end
