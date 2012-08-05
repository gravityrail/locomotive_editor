module LocomotiveEditor
  module Api

    class Base

      include HTTParty
      include Api::Helpers

      def initialize(token, options = {})
        self.auth_token = token
        self.options    = options
        self.class.default_params :auth_token => token #, :content_locale => options[:locale]
      end

    end

  end
end