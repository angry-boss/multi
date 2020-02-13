module Multi
  class Reloader

    #   Middleware used in development to init Apartment for each request
    #   Necessary due to code reload (annoying).
    #   Also see apartment/console for the re-definition of reload! that re-init's Apartment
    def initialize(app)
      @app = app
    end

    def call(env)
      Tenant.init
      @app.call(env)
    end
  end
end
