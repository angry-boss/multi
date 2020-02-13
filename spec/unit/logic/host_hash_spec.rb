require 'spec_helper'
require 'multi/logic/host_hash'

describe Multi::Logic::HostHash do

  subject(:logic){ Multi::Logic::HostHash.new(Proc.new{}, 'example.com' => 'example_tenant') }

  describe "#parse_tenant_name" do
    it "parses the host for a domain name" do
      request = ActionDispatch::Request.new('HTTP_HOST' => 'example.com')
      expect(logic.parse_tenant_name(request)).to eq('example_tenant')
    end

    it "raises TenantNotFound exception if there is no host" do
      request = ActionDispatch::Request.new('HTTP_HOST' => '')
      expect { logic.parse_tenant_name(request) }.to raise_error(Multi::TenantNotFound)
    end

    it "raises TenantNotFound exception if there is no database associated to current host" do
      request = ActionDispatch::Request.new('HTTP_HOST' => 'example2.com')
      expect { logic.parse_tenant_name(request) }.to raise_error(Multi::TenantNotFound)
    end
  end

  describe "#call" do
    it "switches to the proper tenant" do
      expect(Multi::Tenant).to receive(:switch).with('example_tenant')

      elevator.call('HTTP_HOST' => 'example.com')
    end
  end
end
