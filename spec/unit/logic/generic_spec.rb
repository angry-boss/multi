require 'spec_helper'
require 'multi/logic/generic'

describe Multi::Logic::Generic do

  class MyLogic < described_class
    def parse_tenant_name(*)
      'tenant2'
    end
  end

  subject(:logic){ described_class.new(Proc.new{}) }

  describe "#call" do
    it "calls the processor if given" do
      logic = described_class.new(Proc.new{}, Proc.new{'tenant1'})

      expect(Multi::Tenant).to receive(:switch).with('tenant1')

      logic.call('HTTP_HOST' => 'foo.bar.com')
    end

    it "raises if parse_tenant_name not implemented" do
      expect {
        logic.call('HTTP_HOST' => 'foo.bar.com')
      }.to raise_error(RuntimeError)
    end

    it "switches to the parsed db_name" do
      logic = MyLogic.new(Proc.new{})

      expect(Multi::Tenant).to receive(:switch).with('tenant2')

      logic.call('HTTP_HOST' => 'foo.bar.com')
    end

    it "calls the block implementation of `switch`" do
      logic = MyLogic.new(Proc.new{}, Proc.new{'tenant2'})

      expect(Multi::Tenant).to receive(:switch).with('tenant2').and_yield
      logic.call('HTTP_HOST' => 'foo.bar.com')
    end

    it "does not call `switch` if no database given" do
      app = Proc.new{}
      logic = MyLogic.new(app, Proc.new{})

      expect(Multi::Tenant).not_to receive(:switch)
      expect(app).to receive :call

      logic.call('HTTP_HOST' => 'foo.bar.com')
    end
  end
end
