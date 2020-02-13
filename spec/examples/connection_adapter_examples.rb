require 'spec_helper'

shared_examples_for "a connection based apartment adapter" do
  include Multi::Spec::AdapterRequirements

  let(:default_tenant){ subject.switch{ ActiveRecord::Base.connection.current_database } }

  describe "#init" do
    after do
      # Apartment::Tenant.init creates per model connection.
      # Remove the connection after testing not to unintentionally keep the connection across tests.
      Multi.excluded_models.each do |excluded_model|
        excluded_model.constantize.remove_connection
      end
    end

    it "should process model exclusions" do
      Multi.configure do |config|
        config.excluded_models = ["Company"]
      end
      Multi::Tenant.init

      expect(Company.connection.object_id).not_to eq(ActiveRecord::Base.connection.object_id)
    end
  end

  describe "#drop" do
    it "should raise an error for unknown database" do
      expect {
        subject.drop 'unknown_database'
      }.to raise_error(Multi::TenantNotFound)
    end
  end

  describe "#switch!" do
    it "should raise an error if database is invalid" do
      expect {
        subject.switch! 'unknown_database'
      }.to raise_error(Multi::TenantNotFound)
    end
  end
end
