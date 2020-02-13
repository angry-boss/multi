require 'spec_helper'
require 'multi/logic/first_subdomain'

describe Multi::Logic::FirstSubdomain do
  describe "subdomain" do
    subject { described_class.new("test").parse_tenant_name(request) }
    let(:request) { double(:request, :host => "#{subdomain}.example.com") }

    context "one subdomain" do
      let(:subdomain) { "test" }
      it { is_expected.to eq("test") }
    end

    context "nested subdomains" do
      let(:subdomain) { "test1.test2" }
      it { is_expected.to eq("test1") }
    end

    context "no subdomain" do
      let(:subdomain) { nil }
      it { is_expected.to eq(nil) }
    end
  end
end
