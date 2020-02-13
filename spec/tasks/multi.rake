require 'spec_helper'
require 'rake'
require 'multi/migrator'
require 'multi/tenant'

describe "apartment rake tasks" do

  before do
    @rake = Rake::Application.new
    Rake.application = @rake
    load 'tasks/multi'
    # stub out rails tasks
    Rake::Task.define_task('db:migrate')
    Rake::Task.define_task('db:seed')
    Rake::Task.define_task('db:rollback')
    Rake::Task.define_task('db:migrate:up')
    Rake::Task.define_task('db:migrate:down')
    Rake::Task.define_task('db:migrate:redo')
  end

  after do
    Rake.application = nil
    ENV['VERSION'] = nil    # linux users reported env variable carrying on between tests
  end

  after(:all) do
    Multi::Test.load_schema
  end

  let(:version){ '1234' }

  context 'database migration' do

    let(:tenant_names){ 3.times.map{ Multi::Test.next_db } }
    let(:tenant_count){ tenant_names.length }

    before do
      allow(Multi).to receive(:tenant_names).and_return tenant_names
    end

    describe "multi:migrate" do
      before do
        allow(ActiveRecord::Migrator).to receive(:migrate)   # don't care about this
      end

      it "should migrate public and all multi-tenant dbs" do
        expect(Multi::Migrator).to receive(:migrate).exactly(tenant_count).times
        @rake['multi:migrate'].invoke
      end
    end

    describe "multi:migrate:up" do

      context "without a version" do
        before do
          ENV['VERSION'] = nil
        end

        it "requires a version to migrate to" do
          expect{
            @rake['multi:migrate:up'].invoke
          }.to raise_error("VERSION is required")
        end
      end

      context "with version" do

        before do
          ENV['VERSION'] = version
        end

        it "migrates up to a specific version" do
          expect(Multi::Migrator).to receive(:run).with(:up, anything, version.to_i).exactly(tenant_count).times
          @rake['multi:migrate:up'].invoke
        end
      end
    end

    describe "multi:migrate:down" do

      context "without a version" do
        before do
          ENV['VERSION'] = nil
        end

        it "requires a version to migrate to" do
          expect{
            @rake['multi:migrate:down'].invoke
          }.to raise_error("VERSION is required")
        end
      end

      context "with version" do

        before do
          ENV['VERSION'] = version
        end

        it "migrates up to a specific version" do
          expect(Multi::Migrator).to receive(:run).with(:down, anything, version.to_i).exactly(tenant_count).times
          @rake['multi:migrate:down'].invoke
        end
      end
    end

    describe "multi:rollback" do
      let(:step){ '3' }

      it "should rollback dbs" do
        expect(Multi::Migrator).to receive(:rollback).exactly(tenant_count).times
        @rake['multi:rollback'].invoke
      end

      it "should rollback dbs STEP amt" do
        expect(Multi::Migrator).to receive(:rollback).with(anything, step.to_i).exactly(tenant_count).times
        ENV['STEP'] = step
        @rake['multi:rollback'].invoke
      end
    end

    describe "multi:drop" do
      it "should migrate public and all multi-tenant dbs" do
        expect(Multi::Tenant).to receive(:drop).exactly(tenant_count).times
        @rake['multi:drop'].invoke
      end
    end

  end
end
