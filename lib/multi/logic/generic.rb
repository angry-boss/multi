require 'rack/request'
require 'multi/tenant'

module Multi
  module Logic
    #   tenant switching on middleware request
    class Generic

      def initialize(app, processor = nil)
        @app = app
        @processor = processor || method(:parse_tenant_name)
      end

      def call(env)
        request = Rack::Request.new(env)

        database = @processor.call(request)

        if database
          Multi::Tenant.switch(database) { @app.call(env) }
        else
          @app.call(env)
        end
      end

      def parse_tenant_name(request)
        raise "Override"
      end
    end
  end
end
