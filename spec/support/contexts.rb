#   Some shared contexts for specs

shared_context "with default schema", :default_schema => true do
  let(:default_schema){ Multi::Test.next_db }

  before do
    Multi::Test.create_schema(default_schema)
    Multi.default_schema = default_schema
  end

  after do
    # resetting default_schema so we can drop and any further resets won't try to access droppped schema
    Multi.default_schema = nil
    Multi::Test.drop_schema(default_schema)
  end
end

# Some default setup for elevator specs
shared_context "elevators", elevator: true do
  let(:company1)  { mock_model(Company, database: db1).as_null_object }
  let(:company2)  { mock_model(Company, database: db2).as_null_object }

  let(:api)       { Multi::Tenant }

  before do
    Multi.reset # reset all config
    Multi.seed_after_create = false
    Multi.use_schemas = true
    api.reload!(config)
    api.create(db1)
    api.create(db2)
  end

  after do
    api.drop(db1)
    api.drop(db2)
  end
end

shared_context "persistent_schemas", :persistent_schemas => true do
  let(:persistent_schemas){ ['hstore', 'postgis'] }

  before do
    persistent_schemas.map{|schema| subject.create(schema) }
    Multi.persistent_schemas = persistent_schemas
  end

  after do
    Multi.persistent_schemas = []
    persistent_schemas.map{|schema| subject.drop(schema) }
  end
end
