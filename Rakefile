require 'bundler'
require 'appraisal'
require "rubygems"
require "rspec"
require "rspec/core/rake_task"

Bundler.setup
Bundler::GemHelper.install_tasks

RSpec::Core::RakeTask.new(:spec => %w{ db:copy_credentials db:test:prepare }) do |spec|
  spec.pattern = "spec/**/*_spec.rb"
  # spec.rspec_opts = '--order rand:47078'
end

namespace :spec do
  [:tasks, :unit, :adapters, :integration].each do |type|
    RSpec::Core::RakeTask.new(type => :spec) do |spec|
      spec.pattern = "spec/#{type}/**/*_spec.rb"
    end
  end
end

task :console do
  require 'pry'
  require 'multi'
  ARGV.clear
  Pry.start
end

task :default => :spec

namespace :db do
  namespace :test do
    task :prepare => %w{postgres:drop_db postgres:build_db}
  end

  desc "copy sample database credential files over if real files don't exist"
  task :copy_credentials do
    require 'fileutils'
    multi_db_file = 'spec/config/database.yml'
    rails_db_file = 'spec/dummy/config/database.yml'

    FileUtils.copy(multi_db_file + '.sample', multi_db_file, :verbose => true) unless File.exists?(multi_db_file)
    FileUtils.copy(rails_db_file + '.sample', rails_db_file, :verbose => true)         unless File.exists?(rails_db_file)
  end
end

namespace :postgres do
  require 'active_record'
  require "#{File.join(File.dirname(__FILE__), 'spec', 'support', 'config')}"

  desc 'Build the PostgreSQL test databases'
  task :build_db do
    params = []
    params << "-E UTF8"
    params << pg_config['database']
    params << "-U#{pg_config['username']}"
    params << "-h#{pg_config['host']}" if pg_config['host']
    params << "-p#{pg_config['port']}" if pg_config['port']
    %x{ createdb #{params.join(' ')} } rescue "test db already exists"
    ActiveRecord::Base.establish_connection pg_config
    migrate
  end

  desc "drop the PostgreSQL test database"
  task :drop_db do
    puts "dropping database #{pg_config['database']}"
    params = []
    params << pg_config['database']
    params << "-U#{pg_config['username']}"
    params << "-h#{pg_config['host']}" if pg_config['host']
    params << "-p#{pg_config['port']}" if pg_config['port']
    %x{ dropdb #{params.join(' ')} }
  end

end

# TODO clean this up
def config
  Multi::Test.config['connections']
end

def pg_config
  config['postgresql']
end

def activerecord_below_5_2?
  ActiveRecord.version.release < Gem::Version.new('5.2.0')
end

def migrate
  if activerecord_below_5_2?
    ActiveRecord::Migrator.migrate('spec/dummy/db/migrate')
  else
    ActiveRecord::MigrationContext.new('spec/dummy/db/migrate').migrate
  end
end
