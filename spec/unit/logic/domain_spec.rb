require 'spec_helper'
require 'multi/logic/domain'

describe Multi::Logic::Domain do

  subject(:logic){ described_class.new(Proc.new{}) }

  describe "#parse_tenant_name" do
    it "parses the host for a domain name" do
      request = ActionDispatch::Request.new('HTTP_HOST' => 'example.com')
      expect(logic.parse_tenant_name(request)).to eq('example')
    end

    it "ignores a www prefix and domain suffix" do
      request = ActionDispatch::Request.new('HTTP_HOST' => 'www.example.bc.ca')
      expect(logic.parse_tenant_name(request)).to eq('example')
    end

    it "returns nil if there is no host" do
      request = ActionDispatch::Request.new('HTTP_HOST' => '')
      expect(logic.parse_tenant_name(request)).to be_nil
    end
  end

  describe "#call" do
    it "switches to the proper tenant" do
      expect(Multi::Tenant).to receive(:switch).with('example')

      logic.call('HTTP_HOST' => 'www.example.com')
    end
  end
end
