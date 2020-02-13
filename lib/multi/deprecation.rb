require 'active_support/deprecation'

module Multi
  module Deprecation

    def self.warn(message)
      ActiveSupport::Deprecation.warn message
    end
  end
end
