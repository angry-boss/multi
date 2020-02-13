require 'spec_helper'

describe Multi do
  it "should be valid" do
    expect(Multi).to be_a(Module)
  end

  it "should be a valid app" do
    expect(::Rails.application).to be_a(Dummy::Application)
  end
end
