module Multi
  module Spec
    module Setup

      def self.included(base)
        base.instance_eval do
          let(:db1){ Multi::Test.next_db }
          let(:db2){ Multi::Test.next_db }
          let(:connection){ ActiveRecord::Base.connection }

          # This around ensures that we run these hooks before and after
          # any before/after hooks defined in individual tests
          # Otherwise these actually get run after test defined hooks
          around(:each) do |example|

            def config
              db = RSpec.current_example.metadata.fetch(:database, :postgresql)

              Multi::Test.config['connections'][db.to_s].symbolize_keys
            end

            # before
            Multi::Tenant.reload!(config)
            ActiveRecord::Base.establish_connection config

            example.run

            # after
            Rails.configuration.database_configuration = {}
            ActiveRecord::Base.clear_all_connections!

            Multi.excluded_models.each do |model|
              klass = model.constantize

              Multi.connection_class.remove_connection(klass)
              klass.clear_all_connections!
              klass.reset_table_name
            end
            Multi.reset
            Multi::Tenant.reload!
          end
        end
      end
    end
  end
end
