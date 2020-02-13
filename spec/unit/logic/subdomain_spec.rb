require 'spec_helper'
require 'multi/logic/subdomain'

describe Multi::Logic::Subdomain do

  subject(:logic){ described_class.new(Proc.new{}) }

  describe "#parse_tenant_name" do
    context "assuming one tld" do
      it "should parse subdomain" do
        request = ActionDispatch::Request.new('HTTP_HOST' => 'foo.bar.com')
        expect(logic.parse_tenant_name(request)).to eq('foo')
      end

      it "should return nil when no subdomain" do
        request = ActionDispatch::Request.new('HTTP_HOST' => 'bar.com')
        expect(logic.parse_tenant_name(request)).to be_nil
      end
    end

    context "assuming two tlds" do
      it "should parse subdomain in the third level domain" do
        request = ActionDispatch::Request.new('HTTP_HOST' => 'foo.bar.co.uk')
        expect(logic.parse_tenant_name(request)).to eq("foo")
      end

      it "should return nil when no subdomain in the third level domain" do
        request = ActionDispatch::Request.new('HTTP_HOST' => 'bar.co.uk')
        expect(logic.parse_tenant_name(request)).to be_nil
      end
    end

    context "assuming two subdomains" do
      it "should parse two subdomains in the two level domain" do
        request = ActionDispatch::Request.new('HTTP_HOST' => 'foo.xyz.bar.com')
        expect(logic.parse_tenant_name(request)).to eq("foo")
      end

      it "should parse two subdomains in the third level domain" do
        request = ActionDispatch::Request.new('HTTP_HOST' => 'foo.xyz.bar.co.uk')
        expect(logic.parse_tenant_name(request)).to eq("foo")
      end
    end

    context "assuming localhost" do
      it "should return nil for localhost" do
        request = ActionDispatch::Request.new('HTTP_HOST' => 'localhost')
        expect(logic.parse_tenant_name(request)).to be_nil
      end
    end

    context "assuming ip address" do
      it "should return nil for an ip address" do
        request = ActionDispatch::Request.new('HTTP_HOST' => '127.0.0.1')
        expect(logic.parse_tenant_name(request)).to be_nil
      end
    end
  end

  describe "#call" do
    it "switches to the proper tenant" do
      expect(Multi::Tenant).to receive(:switch).with('tenant1')
      logic.call('HTTP_HOST' => 'tenant1.example.com')
    end

    it "ignores excluded subdomains" do
      described_class.excluded_subdomains = %w{foo}

      expect(Multi::Tenant).not_to receive(:switch)

      logic.call('HTTP_HOST' => 'foo.bar.com')

      described_class.excluded_subdomains = nil
    end
  end
end
