require 'yaml'

module Multi
  module Test

    def self.config
      @config ||= YAML.load(ERB.new(IO.read('spec/config/database.yml')).result)
    end
  end
end
